cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "ecoconecta_frontend")

add_executable(${BINARY_NAME} WIN32
  "main.cpp"
)

target_compile_definitions(${BINARY_NAME} PRIVATE "_UNICODE" "UNICODE")

