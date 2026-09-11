cmake_minimum_required(VERSION 3.25)

project(udaet VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql)
find_package(KF6Kirigami REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(udaet
    src/main.cpp
    src/diarystore.cpp
    src/diarystore.h
)

qt_add_qml_module(udaet
    URI org.udaet
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(udaet
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::Sql
        KF6::Kirigami
)

include(GNUInstallDirs)
install(TARGETS udaet
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
