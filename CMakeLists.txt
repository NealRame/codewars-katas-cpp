cmake_minimum_required(VERSION 3.16)

project(Codewars)

set(KATA_LIST_FILE "${CMAKE_SOURCE_DIR}/.katas")

list(APPEND CMAKE_CONFIGURE_DEPENDS "${KATA_LIST_FILE}")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/Scripts/CMake")

include(Conan)

conan_check(VERSION 1.24)
conan_add_remote(
  NAME catchorg
  URL https://api.bintray.com/conan/catchorg/Catch2
)
conan_setup(
  CMAKE_TARGETS
  KEEP_RPATHS
)

enable_testing()

file(STRINGS "${KATA_LIST_FILE}" KATA_LIST)

foreach(KATA ${KATA_LIST})
  string(STRIP "${KATA}" KATA)
  if (NOT KATA MATCHES "^#")
    message(STATUS "Kata: ${KATA}")
    add_executable(${KATA} "${CMAKE_SOURCE_DIR}/Katas/${KATA}.cpp")
    target_compile_features(${KATA} PUBLIC cxx_std_17)
    target_link_libraries(${KATA} CONAN_PKG::Catch2)
    add_test(NAME ${KATA} COMMAND $<TARGET_FILE:${KATA}>)
  endif()
endforeach()
