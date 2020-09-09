cmake_minimum_required(VERSION 3.14)

project(SensorReadoutEditor LANGUAGES CXX)

# project settings
##################
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# external dependencies
#######################
add_subdirectory(lib)
find_package(Qt5 COMPONENTS Core Quick REQUIRED)

# qt settings
#############
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# editor
#######################
file(GLOB_RECURSE EDITOR_SOURCES "src/*.cpp")
file(GLOB_RECURSE EDITOR_HEADERS "src/*.h")

add_executable(SensorReadoutEditor ${EDITOR_SOURCES} ${EDITOR_HEADERS} qml.qrc)

target_compile_definitions(SensorReadoutEditor
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(SensorReadoutEditor PRIVATE Qt5::Core Qt5::Quick SensorReadoutParser)
