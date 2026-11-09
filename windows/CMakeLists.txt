cmake_minimum_required(VERSION 3.14)
project(ecoconecta_frontend LANGUAGES CXX)

set(BINARY_NAME "ecoconecta_frontend")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Configure build options
get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
set(FLUTTER_MANAGED_DIR "${PROJECT_ROOT}/windows/flutter")

add_subdirectory("runner")

