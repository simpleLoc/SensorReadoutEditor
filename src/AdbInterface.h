#pragma once

#include <optional>
#include <iostream>
#include <sstream>

#include <subprocess.hpp>

using subprocess::PipeOption;
using subprocess::RunBuilder;

struct FileInfo {
	size_t size;
	std::string filePath;
	std::string fileDate;
};

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

	static std::optional<std::vector<FileInfo>> listFiles(const std::string& exePath, const std::string& device, const std::string& pattern) {
		static const std::string LISTING_START = "List of devices attached";

		try {
			auto process = subprocess::run(
				{exePath, "-s", device, "shell", "ls", "-l", pattern},
				RunBuilder().cout(PipeOption::pipe)
							.check(true) // expect success
			);
			std::istringstream processOutput(process.cout);
			std::string lineBuffer;
			//collect files
			std::vector<FileInfo> result;
			while(std::getline(processOutput, lineBuffer) && lineBuffer != "") {
				std::istringstream lsLine(lineBuffer);
				std::string partBuffer;
				FileInfo fileInfo;

				if(!std::getline(lsLine, partBuffer, ' ')) { continue; }
				if(!std::getline(lsLine, partBuffer, ' ')) { continue; }
				if(!std::getline(lsLine, partBuffer, ' ')) { continue; }
				if(!std::getline(lsLine, partBuffer, ' ')) { continue; }
				// file size
				lsLine >> fileInfo.size;
				lsLine.seekg(1, std::ios::cur); // skip space char after fileSize
				if(!std::getline(lsLine, fileInfo.fileDate, ' ')) { continue; }
				if(!std::getline(lsLine, partBuffer, ' ')) { continue; }
				fileInfo.fileDate += " " + partBuffer;
				// interpret remaining data as fileName
				if(!std::getline(lsLine, fileInfo.filePath)) { continue; }

				result.push_back(fileInfo);
			}
			return result;
		} catch (...) {
			return {};
		}
	}

	static void deleteFile(const std::string& exePath, const std::string& device, const std::string& filePath) {
		try {
			auto process = subprocess::run(
				{exePath, "-s", device, "shell", "rm", filePath},
				RunBuilder().cout(PipeOption::pipe)
							.check(true) // expect success
			);
		} catch (subprocess::CalledProcessError& err) {
			throw std::runtime_error(err.what());
		}
	}

};
