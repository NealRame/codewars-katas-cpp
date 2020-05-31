cmake_minimum_required(VERSION 3.15.0 FATAL_ERROR)

## ## Conan.cmake
## Call __conan__ commands from your _CMakeLists.txt_ files.

## ### Variables

option(SKIP_CONAN_INSTALL "Skip conan setup" OFF)

## ### Functions

macro(conan_compiler_version)
  if(NOT CONAN_SETUP_COMPILER_VERSION)
    if(CMAKE_CXX_COMPILER_ID STREQUAL AppleClang)
      string(REPLACE "." ";" COMPILER_VERSIONS_NUMBERS ${CMAKE_CXX_COMPILER_VERSION})
      list(POP_FRONT COMPILER_VERSIONS_NUMBERS COMPILER_VERSION_MAJOR)
      list(POP_FRONT COMPILER_VERSIONS_NUMBERS COMPILER_VERSION_MINOR)
      list(APPEND CONAN_SETUP_SETTINGS
        compiler.version=${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR}
      )
    elseif(MSVC)
      if(MSVC_VERSION EQUAL 1200)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=6)
      elseif(MSVC_VERSION EQUAL 1300)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=7)
      elseif(MSVC_VERSION EQUAL 1310)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=7.1)
      elseif(MSVC_VERSION EQUAL 1400)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=8)
      elseif(MSVC_VERSION EQUAL 1500)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=9)
      elseif(MSVC_VERSION EQUAL 1600)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=10)
      elseif(MSVC_VERSION EQUAL 1700)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=11)
      elseif(MSVC_VERSION EQUAL 1800)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=12)
      elseif(MSVC_VERSION EQUAL 1900)
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=14)
      elseif((MSVC_VERSION GREATER_EQUAL 1910) AND (MSVC_VERSION LESS 1920))
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=15)
      elseif((MSVC_VERSION GREATER_EQUAL 1920) AND (MSVC_VERSION LESS 1929))
        list(APPEND CONAN_SETUP_SETTINGS compiler.version=16)
      endif()
    endif()
  endif()
endmacro(conan_compiler_version)

macro(conan_compiler_libcxx)
  if(NOT CONAN_SETUP_COMPILER_LIBCXX)
    if(CMAKE_CXX_COMPILER_ID STREQUAL AppleClang)
      list(APPEND CONAN_SETUP_SETTINGS compiler.libcxx=libc++)
    endif()
  endif()
endmacro(conan_compiler_libcxx)

macro(conan_compiler_id)
  if(NOT CONAN_SETUP_COMPILER)
    if(CMAKE_CXX_COMPILER_ID STREQUAL AppleClang)
      list(APPEND CONAN_SETUP_SETTINGS compiler=apple-clang)
    endif()
  endif()
endmacro(conan_compiler_id)

macro(conan_compiler)
  conan_compiler_id()
  conan_compiler_version()
  conan_compiler_libcxx()
endmacro(conan_compiler)

macro(conan_load_buildinfo)
  if(IS_MULTI_CONFIG
      AND NOT (CONAN_SETUP_SKIP_INSTALL OR SKIP_CONAN_INSTALL))
    set(_CONANBUILDINFO conanbuildinfo_multi.cmake)
  else()
    set(_CONANBUILDINFO conanbuildinfo.cmake)
  endif()

  # Checks for the existence of conanbuildinfo.cmake, and loads it important
  # that it is macro, so variables defined at parent scope
  if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${_CONANBUILDINFO}")
    message(STATUS "Conan: Loading ${_CONANBUILDINFO}")
    include(${CMAKE_CURRENT_BINARY_DIR}/${_CONANBUILDINFO})
  else()
    message(FATAL_ERROR "${_CONANBUILDINFO} doesn't exist in ${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  set(_CONANPATHS "conan_paths.cmake")
  if(EXISTS "${CMAKE_BINARY_DIR}/${_CONANPATHS}")
    message(STATUS "Conan: Loading ${_CONANPATHS}")
    include(${CMAKE_BINARY_DIR}/${_CONANPATHS})
  endif()
endmacro()

## #### conan_setup
## Setup the conan dependencies.
##
## ##### Synopsis:
## ```cmake
## conan_setup(
##   [CONANFILE <conanfile>]
##   [CMAKE_TARGETS]
##   [KEEP_RPATHS]
##   [SKIP_INSTALL]
##   [SETTINGS <settings1=value1>...]
##   [OPTIONS <options1=value1>...]
## )
## ```
##
## ##### Arguments:
## - `CONANFILE <conanfile>` - path to the conanfile, default to ${CMAKE_SOURCE_DIR}/conanfile.txt
## - `CMAKE_TARGETS` - enable CMake targets,
## - `KEEP_RPATHS` - enable keep RPATH,
## - `SKIP_INSTALL` - skip conan install,
## - `SETTINGS <settings1=value1>...` - add settings
## - `OPTIONS <options1=value1>...` - add options.
##
## ##### Example:
## ```cmake
## conan_setup(
##   CONANFILE ${CMAKE_SOURCE_DIR}/conanfile.txt
##   CMAKE_TARGETS
##   KEEP_RPATHS
## )
## ```
macro(conan_setup)
  cmake_parse_arguments(CONAN_SETUP "SKIP_INSTALL;CMAKE_TARGETS;KEEP_RPATHS;" "CONANFILE;PROFILE;COMPILER_VERSION" "SETTINGS;OPTIONS" ${ARGN})

  get_property(IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  if(NOT CONAN)
    find_program(CONAN conan)
    if(NOT CONAN)
      message(FATAL_ERROR "conan command not found.")
    endif()
  endif()

  if(NOT CONAN_SETUP_CONANFILE)
    set(CONAN_SETUP_CONANFILE ${CMAKE_SOURCE_DIR}/conanfile.txt)
  endif()

  if(IS_MULTI_CONFIG)
    list(APPEND CONAN_BUILD_TYPES Debug Release)
    list(APPEND CONAN_ARGS -g cmake_multi)
  elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    list(APPEND CONAN_BUILD_TYPES "Debug")
  else()
    list(APPEND CONAN_BUILD_TYPES "Release")
  endif()

  conan_compiler()

  if(WIN32)
    if(CMAKE_GENERATOR_PLATFORM STREQUAL x64)
      list(APPEND CONAN_SETUP_SETTINGS arch=x86_64)
    else()
      list(APPEND CONAN_SETUP_SETTINGS arch=x86)
    endif()
  endif()

  foreach(SETTING ${CONAN_SETUP_SETTINGS})
    list(APPEND CONAN_ARGS --settings ${SETTING})
  endforeach()

  foreach(OPTION ${CONAN_SETUP_OPTIONS})
    list(APPEND CONAN_ARGS --options ${OPTION})
  endforeach()

  if(CONAN_SETUP_PROFILE)
    list(APPEND CONAN_ARGS "--profile ${CONAN_SETUP_PROFILE}")
  endif()

  if(NOT (CONAN_SETUP_SKIP_INSTALL OR SKIP_CONAN_INSTALL))
    get_filename_component(CONAN_DIR ${CONAN} DIRECTORY)
    if(UNIX)
      set(ENV{PATH} "${CONAN_DIR}:$ENV{PATH}")
    else()
      set(ENV{PATH} "${CONAN_DIR};$ENV{PATH}")
    endif()
    foreach(BUILD_TYPE ${CONAN_BUILD_TYPES})
      execute_process(
        COMMAND
          ${CONAN} install
            ${CONAN_ARGS}
            --settings build_type=${BUILD_TYPE}
            --build missing
            "${CONAN_SETUP_CONANFILE}"
        RESULT_VARIABLE CONAN_RESULT
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      )
    endforeach()
  else()
    message(STATUS "Conan: Skip install")
  endif()

  conan_load_buildinfo()

  if(CONAN_SETUP_CMAKE_TARGETS)
    list(APPEND CONAN_BASIC_SETUP_OPTIONS TARGETS)
  endif()

  if(CONAN_SETUP_KEEP_RPATHS)
    list(APPEND CONAN_BASIC_SETUP_OPTIONS KEEP_RPATHS)
  endif()

  conan_basic_setup(${CONAN_BASIC_SETUP_OPTIONS})
endmacro()

## #### conan_check
## Checks if the conan is available. If a version number is specified, it also
## checks the conan version.
##
## ##### Synopsis:
## ```cmake
## conan_check(
##   [VERSION <major.minor[.patch]>]
## )
## ```
##
## ##### Arguments:
## - `VERSION <major.minor[.patch]>` - the minimum required version.
##
## ##### Example:
## ```cmake
## conan_check(VERSION 1.14)
## ```
function(conan_check)
  cmake_parse_arguments(CONAN_CHECK "" "VERSION" "" ${ARGN})

  if(NOT CONAN)
    find_program(CONAN conan)
    if(NOT CONAN)
      message(FATAL_ERROR "conan command not found.")
    endif()
  endif()

  if(CONAN_CHECK_VERSION)
    execute_process(
      COMMAND ${CONAN} --version
      OUTPUT_VARIABLE CONAN_VERSION_RAW
      ERROR_VARIABLE CONAN_ERROR
      RESULT_VARIABLE CONAN_RESULT
      WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    )
    if(NOT CONAN_RESULT EQUAL 0)
      message(FATAL_ERROR "ERROR: ${CONAN_ERROR}")
    endif()

    separate_arguments(CONAN_VERSION UNIX_COMMAND ${CONAN_VERSION_RAW})
    list(GET CONAN_VERSION 2 CONAN_VERSION)

    message(STATUS "Conan version is ${CONAN_VERSION}")

    if(CONAN_VERSION VERSION_LESS CONAN_CHECK_VERSION)
      message(FATAL_ERROR "Conan version required is ${CONAN_CHECK_VERSION}")
    endif()
  endif()
endfunction()

## #### conan_env
## Setup conan using python virtual environment.
##
## ##### Synopsis:
## ```cmake
## conan_env(
##   [VERSION <major.minor[.patch]>]
## )
##
## ##### Arguments:
## - `VERSION <major.minor[.patch]>` - the conan version to be installed.
##
## ##### Example:
## ```cmake
## conan_env(VERSION 1.14)
## ```
function(conan_env)
  cmake_parse_arguments(CONAN_ENV "" "VERSION" "" ${ARGN})

  set(CONAN_ENV_DIR "${CMAKE_BINARY_DIR}/.conan${CONAN_ENV_VERSION}-env")

  if(NOT (IS_DIRECTORY "${CONAN_ENV_DIR}"))
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    if(Python3_EXECUTABLE)
      message(STATUS "Setup conan environment")

      message(STATUS "  init python virtual environment")
      execute_process(
        COMMAND "${Python3_EXECUTABLE}" -m venv "${CONAN_ENV_DIR}"
        ERROR_VARIABLE __error
        OUTPUT_VARIABLE __output
        RESULT_VARIABLE __result
      )
      if(NOT __result EQUAL 0)
        message(FATAL_ERROR "${__error}")
      endif()

      set(ENV{VIRTUAL_ENV} "${CONAN_ENV_DIR}")
      if(CONAN_ENV_VERSION)
        set(CONAN_PIP_PKG "conan==${CONAN_ENV_VERSION}")
        message(STATUS "  install conan (${CONAN_ENV_VERSION})")
      else()
        set(CONAN_PIP_PKG "conan")
        message(STATUS "  install conan (latest)")
      endif()
      if(UNIX)
        set(PIP "${CONAN_ENV_DIR}/bin/pip")
      else()
        set(PIP "${CONAN_ENV_DIR}/Scripts/pip.exe")
      endif()

      execute_process(
        COMMAND "${PIP}" install "${CONAN_PIP_PKG}"
        ERROR_VARIABLE __error
        OUTPUT_VARIABLE __output
        RESULT_VARIABLE __result
      )
      if(NOT __result EQUAL 0)
        message("PIP is ${PIP}")
        message("__error is ${__error}")
        message("__output is ${__output}")
        message(FATAL_ERROR "__result is ${__result}")
      endif()
    endif()
  endif()

  set(CONAN_ENV_DIR "${CONAN_ENV_DIR}" PARENT_SCOPE)
  if(WIN32)
    set(CONAN_DIR "${CONAN_ENV_DIR}/Scripts" PARENT_SCOPE)
  else()
    set(CONAN_DIR "${CONAN_ENV_DIR}/bin" PARENT_SCOPE)
  endif()
  if(WIN32)
    set(CONAN "${CONAN_ENV_DIR}/Scripts/conan.exe" PARENT_SCOPE)
  else()
    set(CONAN "${CONAN_ENV_DIR}/bin/conan" PARENT_SCOPE)
  endif()
 endfunction()

## #### conan_add_remote
## Add the specified conan remote if it is not already in the conan remote
## list.
##
## ##### Synopsis:
## ```cmake
## conan_add_remote(
##   NAME <remote_name>
##   URL <remote_url>
## )
## ```
##
## ##### Arguments:
## - `NAME <name>`, le nom du remote à enregistrer,
## - `URL <url>`, l'url du remote.
##
## ##### Example:
## ```cmake
## conan_add_remote(
##   NAME foobar
##   URL http://foo.bar.com
## )
## ```
function(conan_add_remote)
  cmake_parse_arguments(CONAN_REMOTE "" "NAME;URL" "" ${ARGN})

  if(NOT CONAN_REMOTE_NAME)
    message(FATAL_ERROR "NAME parameter is required")
  endif()

  if(NOT CONAN_REMOTE_URL)
    message(FATAL_ERROR "URL parameter is required")
  endif()

  if(NOT CONAN)
    find_program(CONAN conan)
    if(NOT CONAN)
      message(FATAL_ERROR "conan command not found.")
    endif()
  endif()

  execute_process(
    COMMAND ${CONAN} remote list --raw
    OUTPUT_VARIABLE CONAN_REMOTE_LIST_RAW
    ERROR_VARIABLE CONAN_ERROR
    RESULT_VARIABLE CONAN_RESULT
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )

  if(NOT CONAN_RESULT EQUAL 0)
    message(FATAL_ERROR "${CONAN_ERROR}")
  endif()

  separate_arguments(CONAN_REMOTE_LIST UNIX_COMMAND ${CONAN_REMOTE_LIST_RAW})

  while(TRUE)
    list(GET CONAN_REMOTE_LIST 0 NAME)
    list(GET CONAN_REMOTE_LIST 1 URL)

    if("${URL}" STREQUAL "${CONAN_REMOTE_URL}")
      message(STATUS "Conan: Remote ${CONAN_REMOTE_NAME}=\"${CONAN_REMOTE_URL}\" already exists.")
      return()
    endif()

    list(LENGTH CONAN_REMOTE_LIST CONAN_REMOTE_LIST_SIZE)
    if(CONAN_REMOTE_LIST_SIZE GREATER 3)
      list(SUBLIST CONAN_REMOTE_LIST 3 -1 CONAN_REMOTE_LIST)
    else()
      break()
    endif()
  endwhile()

  message(STATUS "Conan: Remote ${CONAN_REMOTE_NAME}=\"${CONAN_REMOTE_URL}\" added.")
  execute_process(
    COMMAND ${CONAN} remote add ${CONAN_REMOTE_NAME} ${CONAN_REMOTE_URL}
    ERROR_VARIABLE CONAN_ERROR
    RESULT_VARIABLE CONAN_RESULT
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )

  if(NOT CONAN_RESULT EQUAL 0)
    message(FATAL_ERROR "${CONAN_ERROR}")
  endif()
endfunction()
