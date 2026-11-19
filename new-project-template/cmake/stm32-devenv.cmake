# CMake helpers for STM32CubeMX projects (from the stm32-devenv template).
#
# CubeMX generates CMakeLists.txt only once and never overwrites it, so these
# helpers are called from there by hand. Add, after
# "add_subdirectory(cmake/stm32cubemx)":
#
#   include(cmake/stm32-devenv.cmake)
#   stm32_devenv_quiet_cubemx_headers()
#
# and for your own code, e.g. a library built from src/:
#
#   add_library(app STATIC ${APP_SOURCES})
#   target_include_directories(app PUBLIC ${CMAKE_SOURCE_DIR}/src)
#   target_link_libraries(app PUBLIC stm32cubemx)
#   stm32_devenv_strict_warnings(app)
#
# and, once the executable exists:
#
#   stm32_devenv_post_build(${CMAKE_PROJECT_NAME})


# Treat the vendor include folders of CubeMX's "stm32cubemx" target (HAL,
# CMSIS, middleware: everything under Drivers/ and Middlewares/) as system
# headers. The compiler then reports no warnings from inside them, so strict
# warnings only show up for our own code.
#
# Core/Inc and the middleware glue folders (USB_DEVICE/, FATFS/, ...) are left
# alone on purpose: compilers search system folders only after all normal -I
# folders, and CubeMX's glue headers have generic names (i2c.h, gpio.h, main.h).
# As system headers, a same-named header of our own would silently win.
function(stm32_devenv_quiet_cubemx_headers)
    get_target_property(_inc stm32cubemx INTERFACE_INCLUDE_DIRECTORIES)
    if(NOT _inc)
        return()
    endif()
    set(_vendor "")
    foreach(_dir IN LISTS _inc)
        if(_dir MATCHES "/(Drivers|Middlewares)/")
            list(APPEND _vendor "${_dir}")
        endif()
    endforeach()
    if(_vendor)
        set_property(TARGET stm32cubemx APPEND PROPERTY
            INTERFACE_SYSTEM_INCLUDE_DIRECTORIES ${_vendor})
    endif()
endfunction()


# Strict compiler warnings for one target (C and C++ sources only):
#   -Wall -Wextra -Wpedantic  the broad warning sets
#   -Wshadow                  a local name hides another
#   -Wdouble-promotion        float silently promoted to double (slow on an
#                             FPU that only does single precision)
#   -Wformat=2 -Wformat-truncation  printf-style format problems
#   -Wundef                   #if on an undefined macro
#   -Wconversion              implicit conversions that may change a value
#   -Wno-unused-parameter     HAL callbacks often ignore their parameters
#   -fno-common               duplicate global definitions are a link error
#   -fstack-usage             write each function's stack use to a .su file
function(stm32_devenv_strict_warnings target)
    set(_flags
        -Wall -Wextra -Wpedantic
        -Wshadow
        -Wdouble-promotion
        -Wformat=2 -Wformat-truncation
        -Wundef
        -Wconversion
        -Wno-unused-parameter
        -fno-common
        -fstack-usage
    )
    # The quotes keep the list in one piece inside the generator expression.
    target_compile_options(${target} PRIVATE
        "$<$<COMPILE_LANGUAGE:C,CXX>:${_flags}>")
endfunction()


# After linking, write <name>.hex and <name>.bin next to the ELF and print the
# memory usage (text = flash code, data = initialised RAM, bss = zeroed RAM).
function(stm32_devenv_post_build target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex
                $<TARGET_FILE:${target}>
                $<TARGET_FILE_DIR:${target}>/$<TARGET_FILE_BASE_NAME:${target}>.hex
        COMMAND ${CMAKE_OBJCOPY} -O binary
                $<TARGET_FILE:${target}>
                $<TARGET_FILE_DIR:${target}>/$<TARGET_FILE_BASE_NAME:${target}>.bin
        COMMAND ${CMAKE_SIZE} --format=berkeley $<TARGET_FILE:${target}>
        COMMENT "Writing $<TARGET_FILE_BASE_NAME:${target}>.hex/.bin, memory usage:"
    )
endfunction()
