#pragma once

#include <optional>
#include <iostream>
#include <sstream>

#include <subprocess.hpp>

using subprocess::PipeOption;
using subprocess::RunBuilder;

// TODO: doesn't work for some reason.
// See: https://stackoverflow.com/questions/63968813/why-do-qprocess-qt-5-15-1-and-gdb-lead-to-missing-symbols
//
//		QProcess process;
//		process.start(exePath, {"version"});
//		process.setReadChannel(QProcess::StandardOutput);
//		if(!process.waitForStarted()) { return {}; }
//		process.closeWriteChannel();
//		if(!process.waitForFinished(2000) || process.exitStatus() == QProcess::CrashExit) {
//			process.kill();
//			return {};
//		}
//		auto versionInfo = QString::fromUtf8(process.readLine());
//		if(!versionInfo.startsWith(VERSION_PREFIX)) {
//			return {};
//		}
//		return versionInfo.left(strlen(VERSION_PREFIX) + 1);


class AdbInterface {

public:
	static std::optional<std::string> getVersion(const std::string& exePath) {
		static const std::string VERSION_PREFIX = "Android Debug Bridge version";

		try {
			auto process = subprocess::run(
				{exePath, "version"},
				RunBuilder().cout(PipeOption::pipe)
							.check(true) // expect success
			);
			std::istringstream processOutput(process.cout);
			std::string versionInfo;
			if(!std::getline(processOutput, versionInfo)) { return {}; }
			// try to parse adb's output
			if(versionInfo.rfind(VERSION_PREFIX, 0) != 0) {
				return {};
			}
			return versionInfo.substr(VERSION_PREFIX.length() + 1);
		} catch (...) {
			return {};
		}
	}

	static std::optional<std::vector<std::string>> getDevices(const std::string& exePath) {
		static const std::string LISTING_START = "List of devices attached";

		try {
			auto process = subprocess::run(
				{exePath, "devices"},
				RunBuilder().cout(PipeOption::pipe)
							.check(true) // expect success
			);
			std::istringstream processOutput(process.cout);
			std::string lineBuffer;
			while(std::getline(processOutput, lineBuffer) && lineBuffer != LISTING_START) {}
			if(lineBuffer != LISTING_START) { return {}; }
			// parse device ids
			std::vector<std::string> deviceIds;
			while(std::getline(processOutput, lineBuffer) && lineBuffer != "") {
				if(lineBuffer.length() < 10) { return {}; }
				deviceIds.push_back(lineBuffer.substr(0, 10));
			}
			return deviceIds;
		} catch (...) {
			return {};
		}
	}

	static std::optional<std::vector<std::string>> listFiles(const std::string& exePath, const std::string& device, const std::string& pattern) {
		static const std::string LISTING_START = "List of devices attached";

		try {
			auto process = subprocess::run(
				{exePath, "-s", device, "shell", "ls", pattern},
				RunBuilder().cout(PipeOption::pipe)
							.check(true) // expect success
			);
			std::istringstream processOutput(process.cout);
			std::string lineBuffer;
			//collect files
			std::vector<std::string> filePaths;
			while(std::getline(processOutput, lineBuffer) && lineBuffer != "") {
				filePaths.push_back(lineBuffer);
			}
			return filePaths;
		} catch (...) {
			return {};
		}
	}


//	static std::optional<std::vector<std::string>> getFileListing(const std::string& path) {
//		try {
//			auto process = subprocess::run(
//				{exePath, "version"},
//				RunBuilder().cout(PipeOption::pipe)
//							.check(true) // expect success
//			);
//			std::istringstream processOutput(process.cout);
//			std::string versionInfo;
//			if(!std::getline(processOutput, versionInfo)) { return {}; }
//			// try to parse adb's output
//			if(versionInfo.rfind(VERSION_PREFIX, 0) != 0) {
//				return {};
//			}
//			return versionInfo.substr(strlen(VERSION_PREFIX) + 1);
//		} catch (...) {
//			return {};
//		}
//	}

};
