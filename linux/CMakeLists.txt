cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "ecoconecta_frontend")

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
)

target_compile_options(${BINARY_NAME} PRIVATE -Wall -Werror)

