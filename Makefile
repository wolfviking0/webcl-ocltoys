#
#  Makefile
#  Licence : https://github.com/wolfviking0/webcl-translator/blob/master/LICENSE
#
#  Created by Anthony Liot.
#  Copyright (c) 2013 Anthony Liot. All rights reserved.
#

# Default parameter
DEB = 0
VAL = 0
NAT = 0
ORIG= 0
FAST= 1

# Chdir function
CHDIR_SHELL := $(SHELL)
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

# Current Folder
CURRENT_ROOT:=$(PWD)

# Current Boost
CURRENT_BOOST:=$(CURRENT_ROOT)/externs/boost

# Emscripten Folder
EMSCRIPTEN_ROOT:=$(CURRENT_ROOT)/../webcl-translator/emscripten

# Native build
ifeq ($(NAT),1)
$(info ************ NATIVE : NO DEPENDENCIES  ************)

CXX = clang++
CC  = clang

BUILD_FOLDER = $(CURRENT_ROOT)/bin/
EXTENSION = .out

ifeq ($(DEB),1)
$(info ************ NATIVE : DEBUG = 1        ************)

CFLAGS = -O0 -framework OpenCL -framework OpenGL -framework GLUT -framework CoreFoundation -framework AppKit -framework IOKit -framework CoreVideo -framework CoreGraphics

else
$(info ************ NATIVE : DEBUG = 0        ************)

CFLAGS = -O2 -framework OpenCL -framework OpenGL -framework GLUT -framework CoreFoundation -framework AppKit -framework IOKit -framework CoreVideo -framework CoreGraphics

endif

# Emscripten build
else
ifeq ($(ORIG),1)
$(info ************ EMSCRIPTEN : SUBMODULE     = 0 ************)

EMSCRIPTEN_ROOT:=$(CURRENT_ROOT)/../emscripten
else
$(info ************ EMSCRIPTEN : SUBMODULE     = 1 ************)
endif

CXX = $(EMSCRIPTEN_ROOT)/em++
CC  = $(EMSCRIPTEN_ROOT)/emcc

BUILD_FOLDER = $(CURRENT_ROOT)/build/
EXTENSION = .js
GLOBAL =

ifeq ($(DEB),1)
$(info ************ EMSCRIPTEN : DEBUG         = 1 ************)

GLOBAL += EMCC_DEBUG=1

CFLAGS = -s OPT_LEVEL=1 -s DEBUG_LEVEL=1 -s CL_PRINT_TRACE=1 -s WARN_ON_UNDEFINED_SYMBOLS=1 -s CL_DEBUG=1 -s CL_GRAB_TRACE=1 -s CL_CHECK_VALID_OBJECT=1
else
$(info ************ EMSCRIPTEN : DEBUG         = 0 ************)

CFLAGS = -s OPT_LEVEL=3 -s DEBUG_LEVEL=0 -s CL_PRINT_TRACE=0 -s DISABLE_EXCEPTION_CATCHING=0 -s WARN_ON_UNDEFINED_SYMBOLS=1 -s CL_DEBUG=0 -s CL_GRAB_TRACE=0 -s CL_CHECK_VALID_OBJECT=0
endif

ifeq ($(VAL),1)
$(info ************ EMSCRIPTEN : VALIDATOR     = 1 ************)

PREFIX = val_

CFLAGS += -s CL_VALIDATOR=1
else
$(info ************ EMSCRIPTEN : VALIDATOR     = 0 ************)
endif

ifeq ($(FAST),1)
$(info ************ EMSCRIPTEN : FAST_COMPILER = 1 ************)

GLOBAL += EMCC_FAST_COMPILER=1
else
$(info ************ EMSCRIPTEN : FAST_COMPILER = 0 ************)
endif

endif

SOURCES_common			=	$(CURRENT_ROOT)/ocltoys-v1.0/common/ocltoy.cpp $(CURRENT_ROOT)/ocltoys-v1.0/common/utils.cpp

SOURCES_boost			=	$(CURRENT_BOOST)/libs/system/src/error_code.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/options_description.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/cmdline.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/variables_map.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/value_semantic.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/positional_options.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/convert.cpp \
							$(CURRENT_BOOST)/libs/program_options/src/utf8_codecvt_facet.cpp \
							$(CURRENT_BOOST)/libs/regex/src/regex.cpp \
							$(CURRENT_BOOST)/libs/regex/src/cpp_regex_traits.cpp \
							$(CURRENT_BOOST)/libs/regex/src/regex_raw_buffer.cpp \
							$(CURRENT_BOOST)/libs/regex/src/regex_traits_defaults.cpp \
							$(CURRENT_BOOST)/libs/regex/src/static_mutex.cpp \
							$(CURRENT_BOOST)/libs/regex/src/instances.cpp \
							$(CURRENT_BOOST)/libs/filesystem/src/operations.cpp \
							$(CURRENT_BOOST)/libs/filesystem/src/path.cpp \
							$(CURRENT_BOOST)/libs/filesystem/src/utf8_codecvt_facet.cpp \

SOURCES_jugcler			=	$(SOURCES_common) $(SOURCES_boost) animation.cpp jugCLer.cpp scene.cpp
SOURCES_juliagpu		=	$(SOURCES_common) $(SOURCES_boost) juliagpu.cpp
SOURCES_mandelgpu		=	$(SOURCES_common) $(SOURCES_boost) mandelgpu.cpp
SOURCES_smallptgpu		=	$(SOURCES_common) $(SOURCES_boost) smallptgpu.cpp

INCLUDES_common			=	-I$(CURRENT_BOOST)/ -I$(CURRENT_ROOT)/ocltoys-v1.0/common/ -I$(EMSCRIPTEN_ROOT)/system/include/

ifeq ($(NAT),0)

KERNEL_jugcler			= 	--preload-file trace.cl
KERNEL_juliagpu			= 	--preload-file preprocessed_rendering_kernel.cl
KERNEL_mandelgpu		= 	--preload-file rendering_kernel_float4.cl
KERNEL_smallptgpu		= 	--preload-file preprocessed_rendering_kernel_smallpt.cl --preload-file scenes/caustic.scn --preload-file scenes/caustic3.scn --preload-file scenes/cornell_fog.scn --preload-file scenes/cornell_large.scn --preload-file scenes/cornell_sss.scn --preload-file scenes/cornell.scn --preload-file scenes/simple.scn 

CFLAGS_jugcler			=	-s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1
CFLAGS_juliagpu			=	-s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1
CFLAGS_mandelgpu		=	-s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1
CFLAGS_smallptgpu		=	-s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1

VALPARAM_jugcler		=	-s CL_VAL_PARAM='[""]'
VALPARAM_juliagpu		=	-s CL_VAL_PARAM='[""]'
VALPARAM_mandelgpu		=	-s CL_VAL_PARAM='[""]'
VALPARAM_smallptgpu		=	-s CL_VAL_PARAM='["-DPARAM_MAX_DEPTH:6","-DPARAM_DEFAULT_SIGMA_S:5.000000e-03f","-DPARAM_DEFAULT_SIGMA_A:0.000000e+00f"]'

else

COPY_jugcler			= 	cp trace.cl $(BUILD_FOLDER) &&
COPY_juliagpu			= 	cp preprocessed_rendering_kernel.cl $(BUILD_FOLDER) &&
COPY_mandelgpu			= 	cp rendering_kernel_float4.cl $(BUILD_FOLDER) &&
COPY_smallptgpu			= 	mkdir -p $(BUILD_FOLDER)scenes/ && cp -rf scenes/ $(BUILD_FOLDER)scenes/ && cp preprocessed_rendering_kernel_smallpt.cl $(BUILD_FOLDER) &&

endif

.PHONY:    
	all clean

all: \
	all_1 all_2 all_3

all_1: \
	jugcler_sample juliagpu_sample

all_2: \
	mandelgpu_sample

all_3: \
	smallptgpu_sample

# Create build folder is necessary))
mkdir:
	mkdir -p $(BUILD_FOLDER);

jugcler_sample: mkdir
	$(call chdir,ocltoys-v1.0/jugCLer/)
	$(COPY_jugcler) 	$(GLOBAL) $(CXX) $(CFLAGS) $(CFLAGS_jugcler) 	$(INCLUDES_common) 	$(SOURCES_jugcler) 		$(VALPARAM_jugcler) 	$(KERNEL_jugcler) 		-o $(BUILD_FOLDER)$(PREFIX)jugcler$(EXTENSION) 

juliagpu_sample: mkdir
	$(call chdir,ocltoys-v1.0/juliagpu/)
	$(COPY_juliagpu) 	$(GLOBAL) $(CXX) $(CFLAGS) $(CFLAGS_juliagpu)	$(INCLUDES_common)	$(SOURCES_juliagpu)		$(VALPARAM_juliagpu) 	$(KERNEL_juliagpu) 		-o $(BUILD_FOLDER)$(PREFIX)juliagpu$(EXTENSION) 

mandelgpu_sample: mkdir
	$(call chdir,ocltoys-v1.0/mandelgpu/)
	$(COPY_mandelgpu) 	$(GLOBAL) $(CXX) $(CFLAGS) $(CFLAGS_mandelgpu)	$(INCLUDES_common)	$(SOURCES_mandelgpu)	$(VALPARAM_mandelgpu) 	$(KERNEL_mandelgpu) 	-o $(BUILD_FOLDER)$(PREFIX)mandelgpu$(EXTENSION) 

smallptgpu_sample: mkdir
	$(call chdir,ocltoys-v1.0/smallptgpu/)
	$(COPY_smallptgpu) 	$(GLOBAL) $(CXX) $(CFLAGS) $(CFLAGS_smallptgpu)	$(INCLUDES_common)	$(SOURCES_smallptgpu)	$(VALPARAM_smallptgpu) 	$(KERNEL_smallptgpu) 	-o $(BUILD_FOLDER)$(PREFIX)smallptgpu$(EXTENSION) 

clean:
	rm -rf bin/
	mkdir -p bin/
	mkdir -p tmp/
	cp build/memoryprofiler.js tmp/ && cp build/settings.js tmp/ && cp build/index.html tmp/
	rm -rf build/
	mkdir -p build/
	cp tmp/memoryprofiler.js build/ && cp tmp/settings.js build/ && cp tmp/index.html build/
	rm -rf tmp/
	$(EMSCRIPTEN_ROOT)/emcc --clear-cache

