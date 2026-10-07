# Native part of the Android build: libSDL2.so + libmain.so (recompiled game + runtime).
# Configured by build.ps1 with the NDK toolchain; sources come from ../CTRStaticRecomp.
cmake_minimum_required(VERSION 3.20)
project(CTRStaticRecompAndroid C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

set(CTR_ROOT "${CMAKE_SOURCE_DIR}/../CTRStaticRecomp" CACHE PATH "CTRStaticRecomp checkout (runtime sources)")
set(GEN_DIR "${CMAKE_SOURCE_DIR}/build/gen" CACHE PATH "Output of gen/recomp.py")
if(NOT EXISTS "${GEN_DIR}/func_table.c")
  message(FATAL_ERROR "Run gen/recomp.py first (see build.ps1); expected ${GEN_DIR}/func_table.c")
endif()

# ---- SDL2 (shared: SDLActivity loads libSDL2.so, then libmain.so) -----------
set(SDL_SHARED ON CACHE BOOL "" FORCE)
set(SDL_STATIC OFF CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
include(FetchContent)
FetchContent_Declare(SDL2 GIT_REPOSITORY https://github.com/libsdl-org/SDL.git GIT_TAG release-2.30.9 GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(SDL2)

# 16 KB page alignment (required on devices with 16 KB pages)
add_link_options(-Wl,-z,max-page-size=16384)

# ---- generated code ---------------------------------------------------------
file(GLOB GEN_SOURCES "${GEN_DIR}/funcs_*.c" "${GEN_DIR}/func_table.c")
add_library(ctr_gen STATIC ${GEN_SOURCES})
target_include_directories(ctr_gen PUBLIC "${CTR_ROOT}/runtime" "${GEN_DIR}")
target_compile_options(ctr_gen PRIVATE -O2 -fwrapv -fno-strict-aliasing -w)

# ---- runtime: libmain.so (SDL calls SDL_main in it) --------------------------
set(RT "${CTR_ROOT}/runtime")
add_library(main SHARED
  ${RT}/main.cpp ${RT}/cpu.cpp ${RT}/hw.cpp ${RT}/bios.cpp ${RT}/gte.cpp ${RT}/gpu.cpp
  ${RT}/spu.cpp ${RT}/cdrom.cpp ${RT}/sio.cpp ${RT}/mdec.cpp ${RT}/crash.cpp ${RT}/hooks.cpp
  ${RT}/pgxp.cpp ${RT}/jmp.c)
target_include_directories(main PRIVATE "${RT}")
target_compile_options(main PRIVATE -O2 -fwrapv -fno-strict-aliasing -Wall -Wno-unused-variable -Wno-unused-function)
target_link_libraries(main PRIVATE ctr_gen SDL2::SDL2 android log)
