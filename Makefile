EMCC:=/Volumes/APPLE_MEDIA/WORKSPACE/webcl/webcl-translator/emscripten

EMSCRIPTEN = $(EMCC)
CXX = $(EMSCRIPTEN)/emcc
AR = $(EMSCRIPTEN)/emar
EMCONFIGURE = $(EMSCRIPTEN)/emconfigure
EMMAKE = $(EMSCRIPTEN)/emmake

CHDIR_SHELL := $(SHELL)
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

DEB=0

DEBUG = -O0 -s OPENCL_PRINT_TRACE=1 -s DISABLE_EXCEPTION_CATCHING=0 -s OPENCL_OLD_VERSION=0 -s WARN_ON_UNDEFINED_SYMBOLS=1 -s OPENCL_PROFILE=1 -s OPENCL_DEBUG=1 -s OPENCL_GRAB_TRACE=1 -s OPENCL_CHECK_SET_POINTER=1 -s OPENCL_CHECK_VALID_OBJECT=1

NO_DEBUG = -03 -s OPENCL_OLD_VERSION=0 -s WARN_ON_UNDEFINED_SYMBOLS=0 -s OPENCL_PROFILE=1 -s OPENCL_DEBUG=0 -s OPENCL_GRAB_TRACE=0 -s OPENCL_PRINT_TRACE=0 -s OPENCL_CHECK_SET_POINTER=0 -s OPENCL_CHECK_VALID_OBJECT=0

ifeq ($(DEB),1)
MODE=$(DEBUG)
$(info ************  Mode DEBUG : Enabled ************)
else
MODE=$(NO_DEBUG)
$(info ************  Mode DEBUG : Disabled ************)
endif
$(info )
$(info )

#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#
# BUILD
#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#		

BOOST_SRC = \
		../../boost_1_54_0/libs/system/src/error_code.cpp \
		../../boost_1_54_0/libs/program_options/src/options_description.cpp \
		../../boost_1_54_0/libs/program_options/src/cmdline.cpp \
		../../boost_1_54_0/libs/program_options/src/variables_map.cpp \
		../../boost_1_54_0/libs/program_options/src/value_semantic.cpp \
		../../boost_1_54_0/libs/program_options/src/positional_options.cpp \
		../../boost_1_54_0/libs/program_options/src/convert.cpp \
		../../boost_1_54_0/libs/regex/src/regex.cpp \
		../../boost_1_54_0/libs/regex/src/cpp_regex_traits.cpp \
		../../boost_1_54_0/libs/regex/src/regex_raw_buffer.cpp \
		../../boost_1_54_0/libs/regex/src/regex_traits_defaults.cpp \
		../../boost_1_54_0/libs/regex/src/static_mutex.cpp \
		../../boost_1_54_0/libs/regex/src/instances.cpp \
		../../boost_1_54_0/libs/filesystem/src/operations.cpp \

COMMON_SRC = \
		../common/ocltoy.cpp \
		../common/utils.cpp \

all: jugCLer_sample juliagpu_sample mandelgpu_sample smallptgpu_sample

jugCLer_sample:
	$(call chdir,ocltoys/jugCLer/)
	JAVA_HEAP_SIZE=8096m EMCC_DEBUG=1 $(CXX) \
		animation.cpp \
		jugCLer.cpp \
		scene.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
	$(MODE) -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../boost_1_54_0/ \
	--preload-file trace.cl \
	-o ../../build/jugCLer.js

juliagpu_sample:
	$(call chdir,ocltoys/juliagpu/)
	JAVA_HEAP_SIZE=8096m EMCC_DEBUG=1 $(CXX) \
		juliagpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
	$(MODE) -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../boost_1_54_0/ \
	--preload-file rendering_kernel.cl \
	-o ../../build/juliagpu.js
	
mandelgpu_sample:
	$(call chdir,ocltoys/mandelgpu/)
	JAVA_HEAP_SIZE=8096m EMCC_DEBUG=1 $(CXX) \
		mandelgpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
	$(MODE) -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../boost_1_54_0/ \
	--preload-file rendering_kernel_float4.cl \
	--preload-file rendering_kernel.cl \
	-o ../../build/mandelgpu.js

smallptgpu_sample:
	$(call chdir,ocltoys/smallptgpu/)
	JAVA_HEAP_SIZE=8096m EMCC_DEBUG=1 $(CXX) \
		smallptgpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
	$(MODE) -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../boost_1_54_0/ \
	--preload-file preprocessed_rendering_kernel.cl \
	--preload-file scenes/caustic.scn \
	--preload-file scenes/caustic3.scn \
	--preload-file scenes/cornell_fog.scn \
	--preload-file scenes/cornell_large.scn \
	--preload-file scenes/cornell_sss.scn \
	--preload-file scenes/cornell.scn \
	--preload-file scenes/simple.scn \
	-o ../../build/smallptgpu.js

smallptgpu_sample_osx:
	$(call chdir,ocltoys/smallptgpu/)
	clang++ \
		smallptgpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
		-D__EMSCRIPTEN__ \
		-I../common/ \
		-I../../boost_1_54_0/ \
		-I ./ -I $(EMCC)/system/include/ -framework OpenCL -framework OpenGL -framework GLUT \
		-lboost_filesystem-mt -lboost_program_options-mt \
		-o smallptgpu.out

clean:
	$(call chdir,build/)
	mkdir tmp
	cp memoryprofiler.js tmp/
	cp settings.js tmp/
	rm -f *.data
	rm -f *.js
	rm -f *.map
	cp tmp/memoryprofiler.js ./
	cp tmp/settings.js ./
	rm -rf tmp/
	$(CXX) --clear-cache

