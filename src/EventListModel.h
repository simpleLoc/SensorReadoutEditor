#pragma once

#include <QVariant>
#include <QAbstractListModel>

#include "UiModels.h"

class EventListModel : public QAbstractListModel {
	Q_OBJECT
	Q_PROPERTY(EventList* eventList READ eventList WRITE setEventList NOTIFY eventListChanged)

	enum {
		DataRole = Qt::UserRole
	};

private:
	EventList* m_eventList = nullptr;
	void assertEventListNotNull() const {
		if(m_eventList == nullptr) { throw std::runtime_error("EventList not set."); }
	}

public:
	explicit EventListModel(QObject* parent = nullptr) : QAbstractListModel(parent) {}

	EventList* eventList() const { return m_eventList; }
	void setEventList(EventList* eventList) {
		emit beginResetModel();

		if(m_eventList) { m_eventList->disconnect(this); }
		m_eventList = eventList;
		if(m_eventList) {
			connect(m_eventList, &EventList::preReset, this, &EventListModel::beginResetModel);
			connect(m_eventList, &EventList::postReset, this, &EventListModel::endResetModel);

			connect(m_eventList, &EventList::postEventChange, this, [=](int index) {
				emit dataChanged(createIndex(index, 0), createIndex(index, 0));
			});

			connect(m_eventList, &EventList::preEventInserted, this, [=](int index) {
				beginInsertRows(QModelIndex(), index, index);
			});
			connect(m_eventList, &EventList::postEventInserted, this, &EventListModel::endInsertRows);

			connect(m_eventList, &EventList::preEventRemoved, this, [=](int index) {
				beginRemoveRows(QModelIndex(), index, index);
			});
			connect(m_eventList, &EventList::postEventRemoved, this, &EventListModel::endRemoveRows);
		}

		emit endResetModel();
		emit eventListChanged();
	}

signals:
	void eventListChanged();

public: // Interface API
	int rowCount(const QModelIndex&) const override {
		assertEventListNotNull();
		return m_eventList->len();
	}
	QVariant data(const QModelIndex &index, int role) const override {
		assertEventListNotNull();
		if(!index.isValid()) { return QVariant(); }
		if(role == DataRole) {
			return QVariant::fromValue(m_eventList->getEventAt(index.row()));
		}
		return QVariant();
	}
	bool setData(const QModelIndex& index, const QVariant& value, int role) override {
		assertEventListNotNull();
		if(!index.isValid()) { return false; }
		EventUiModel event = qvariant_cast<EventUiModel>(value);
		return m_eventList->setEventAt(index.row(), event);
	}
	Qt::ItemFlags flags(const QModelIndex &index) const override {
		assertEventListNotNull();
		if(!index.isValid()) { return Qt::NoItemFlags; }
		return Qt::ItemIsEditable;
	}
	QHash<int, QByteArray> roleNames() const override {
		return {
			{DataRole, QByteArray("model")}
		};
	}
};
