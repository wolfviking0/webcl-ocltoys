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
CURRENT_BOOST:=$(CURRENT_ROOT)/../boost

# Emscripten Folder
EMSCRIPTEN_ROOT:=$(CURRENT_ROOT)/../webcl-translator/emscripten

# Native build
ifeq ($(NAT),1)
$(info ************ NATIVE : DEPENDENCIES (GLEW / GLFW3) ************)

CXX = clang++
CC  = clang

BUILD_FOLDER = $(CURRENT_ROOT)/bin/
EXTENSION = .out

ifeq ($(DEB),1)
$(info ************ NATIVE : DEBUG = 1                   ************)

CFLAGS = -O0 -framework OpenCL -framework OpenGL -framework GLUT -framework CoreFoundation -framework AppKit -framework IOKit -framework CoreVideo -framework CoreGraphics -lGLEW -lglfw3

else
$(info ************ NATIVE : DEBUG = 0                   ************)

CFLAGS = -O2 -framework OpenCL -framework OpenGL -framework GLUT -framework CoreFoundation -framework AppKit -framework IOKit -framework CoreVideo -framework CoreGraphics -lGLEW -lglfw3

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

SOURCES_jugcler			=	$(SOURCES_common) $(SOURCES_boost) animation.cpp jugCLer.cpp scene.cpp

INCLUDES_common			=	-I$(CURRENT_BOOST)/ -I$(CURRENT_ROOT)/ocltoys-v1.0/common/ -I$(CURRENT_ROOT)/externs/include/ -I$(EMSCRIPTEN_ROOT)/system/include/

ifeq ($(NAT),0)

KERNEL_jugcler			= 	--preload-file trace.cl

CFLAGS_jugcler			=	-s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1

else

COPY_jugcler			= 	cp trace.cl $(BUILD_FOLDER) &&

endif

.PHONY:    
	all clean

all: \
	all_1 all_2 all_3

all_1: \
	jugcler_sample

all_2: \


all_3: \

# Create build folder is necessary))
mkdir:
	mkdir -p $(BUILD_FOLDER);

jugcler_sample: mkdir
	$(call chdir,ocltoys-v1.0/jugCLer/)
	$(COPY_jugcler) 		$(GLOBAL) $(CXX) $(CFLAGS) $(CFLAGS_jugcler) $(INCLUDES_common) $(SOURCES_jugcler) $(KERNEL_jugcler) -o $(BUILD_FOLDER)$(PREFIX)jugcler$(EXTENSION) 

clean:
	rm -rf bin/
	mkdir bin/
	mkdir tmp/
	cp js/memoryprofiler.js tmp/ && cp js/settings.js tmp/ && cp js/index.html tmp/
	rm -rf js/
	mkdir js/
	cp tmp/memoryprofiler.js js/ && cp tmp/settings.js js/ && cp tmp/index.html js/
	rm -rf tmp/
	../emscripten/emcc --clear-cache

#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#
# BUILD
#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#		

# BOOST_SRC = \
# 		$(BOOST)/libs/system/src/error_code.cpp \
# 		$(BOOST)/libs/program_options/src/options_description.cpp \
# 		$(BOOST)/libs/program_options/src/cmdline.cpp \
# 		$(BOOST)/libs/program_options/src/variables_map.cpp \
# 		$(BOOST)/libs/program_options/src/value_semantic.cpp \
# 		$(BOOST)/libs/program_options/src/positional_options.cpp \
# 		$(BOOST)/libs/program_options/src/convert.cpp \
# 		$(BOOST)/libs/program_options/src/utf8_codecvt_facet.cpp \
# 		$(BOOST)/libs/regex/src/regex.cpp \
# 		$(BOOST)/libs/regex/src/cpp_regex_traits.cpp \
# 		$(BOOST)/libs/regex/src/regex_raw_buffer.cpp \
# 		$(BOOST)/libs/regex/src/regex_traits_defaults.cpp \
# 		$(BOOST)/libs/regex/src/static_mutex.cpp \
# 		$(BOOST)/libs/regex/src/instances.cpp \
# 		$(BOOST)/libs/filesystem/src/operations.cpp \

# COMMON_SRC = \
# 		../../ocltoys-v1.0/common/ocltoy.cpp \
# 		../../ocltoys-v1.0/common/utils.cpp \

# all: all_1 all_2 all_3

# all_1: \
# 	build_lib \
# 	jugCLer_sample \

# all_2: \
# 	juliagpu_sample \

# all_3: \
# 	mandelgpu_sample \
# 	smallptgpu_sample \

# build_lib:
# 	$(call chdir,externs/lib/)
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) $(COMMON_SRC) -I$(BOOST) -I../../ocltoys-v1.0/common/ -o libcommon.o
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) $(BOOST_SRC) -I../../externs/include/ -o libboost.o	

# jugCLer_sample:
# 	$(call chdir,ocltoys-v1.0/jugCLer/)
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
# 		animation.cpp \
# 		jugCLer.cpp \
# 		scene.cpp \
# 		../../externs/lib/libcommon.o \
# 		../../externs/lib/libboost.o \
# 	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
# 	-I../common/ \
# 	-I../../externs/include/ \
# 	--preload-file trace.cl \
# 	-o ../../build/$(PREFIX)toys_jugCLer.js

# juliagpu_sample:
# 	$(call chdir,ocltoys-v1.0/juliagpu/)
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
# 		juliagpu.cpp \
# 		../../externs/lib/libcommon.o \
# 		../../externs/lib/libboost.o \
# 	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
# 	-I../common/ \
# 	-I../../externs/include/ \
# 	--preload-file preprocessed_rendering_kernel.cl \
# 	--preload-file rendering_kernel.cl \
# 	-o ../../build/$(PREFIX)toys_juliagpu.js

# mandelgpu_sample:
# 	$(call chdir,ocltoys-v1.0/mandelgpu/)
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
# 		mandelgpu.cpp \
# 		../../externs/lib/libcommon.o \
# 		../../externs/lib/libboost.o \
# 	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
# 	-I../common/ \
# 	-I../../externs/include/ \
# 	--preload-file rendering_kernel_float4.cl \
# 	--preload-file rendering_kernel.cl \
# 	-o ../../build/$(PREFIX)toys_mandelgpu.js

# smallptgpu_sample:
# 	$(call chdir,ocltoys-v1.0/smallptgpu/)
# 	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
# 		smallptgpu.cpp \
# 		../../externs/lib/libcommon.o \
# 		../../externs/lib/libboost.o \
# 	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 -s TOTAL_MEMORY=1024*1024*100 \
# 	-I../common/ \
# 	-I../../externs/include/ \
# 	--preload-file preprocessed_rendering_kernel.cl \
# 	--preload-file scenes/caustic.scn \
# 	--preload-file scenes/caustic3.scn \
# 	--preload-file scenes/cornell_fog.scn \
# 	--preload-file scenes/cornell_large.scn \
# 	--preload-file scenes/cornell_sss.scn \
# 	--preload-file scenes/cornell.scn \
# 	--preload-file scenes/simple.scn \
# 	-o ../../build/$(PREFIX)toys_smallptgpu.js

# juliagpu_sample_osx:
# 	$(call chdir,ocltoys-v1.0/juliagpu/)
# 	clang++ \
# 		juliagpu.cpp \
# 		$(COMMON_SRC) \
# 		$(BOOST_SRC) \
# 		-D__EMSCRIPTEN__ \
# 		-I../common/ \
# 		-I../../externs/include/ \
# 		-I./ -I$(EMSCRIPTEN_ROOT)/system/include/ -framework OpenCL -framework OpenGL -framework GLUT \
# 		-lboost_filesystem-mt -lboost_program_options-mt \
# 		-o juliagpu.out
		
# smallptgpu_sample_osx:
# 	$(call chdir,ocltoys-v1.0/smallptgpu/)
# 	clang++ \
# 		smallptgpu.cpp \
# 		$(COMMON_SRC) \
# 		$(BOOST_SRC) \
# 		-D__EMSCRIPTEN__ \
# 		-I../common/ \
# 		-I../../externs/include/ \
# 		-I./ -I$(EMSCRIPTEN_ROOT)/system/include/ -framework OpenCL -framework OpenGL -framework GLUT \
# 		-lboost_filesystem-mt -lboost_program_options-mt \
# 		-o smallptgpu.out


