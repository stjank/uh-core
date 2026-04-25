configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/config.h)

add_library(project project.cpp)
target_include_directories(project PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
