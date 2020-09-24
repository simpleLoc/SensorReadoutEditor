# SensorReadoutParsers (https://github.com/simpleLoc/SensorReadoutParsers)
add_subdirectory(SensorReadoutParsers/CPP/)

# SortFilterProxyModel (https://github.com/oKcerG/SortFilterProxyModel)
add_definitions(-fPIC)
add_subdirectory(SortFilterProxyModel/)
remove_definitions(-fPIC)

# subprocess.h (https://github.com/sheredom/subprocess.h)
add_subdirectory(subprocess)
