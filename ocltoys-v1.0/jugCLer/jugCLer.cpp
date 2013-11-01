/***************************************************************************
 *   Copyright (C) 1998-2013 by authors (see AUTHORS.txt )                 *
 *                                                                         *
 *   This file is part of OCLToys.                                         *
 *                                                                         *
 *   OCLToys is free software; you can redistribute it and/or modify       *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   OCLToys is distributed in the hope that it will be useful,            *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 *                                                                         *
 *   OCLToys website: http://code.google.com/p/ocltoys                     *
 ***************************************************************************/

#include <fstream>
#include <iostream>
#include <boost/format.hpp>

#include "ocltoy.h"

#include "scene.h"
#include "animation.h"

static unsigned int TextureId;
static unsigned int TextureTarget = GL_TEXTURE_2D;
static unsigned int TextureInternal             = GL_RGBA;
static unsigned int TextureFormat               = GL_RGBA;
static unsigned int TextureType                 = GL_UNSIGNED_BYTE;
static unsigned int ActiveTextureUnit           = GL_TEXTURE1_ARB;
static size_t TextureTypeSize                   = sizeof(float);

static float VertexPos[4][2]            = { { -1.0f, -1.0f },
                                            { +1.0f, -1.0f },
                                            { +1.0f, +1.0f },
                                            { -1.0f, +1.0f } };
static float TexCoords[4][2];

static void CreateTexture(unsigned int width, unsigned int height) {    
    if(TextureId)
        glDeleteTextures(1, &TextureId);
    TextureId = 0;
    
    printf("Creating Texture %d x %d...\n", width, height);
    
#ifndef __EMSCRIPTEN__
    glActiveTextureARB(ActiveTextureUnit);
#else
    glActiveTexture(ActiveTextureUnit);
#endif
    
    glGenTextures(1, &TextureId);
    glBindTexture(TextureTarget, TextureId);

#ifndef __EMSCRIPTEN__
    glTexParameteri(TextureTarget, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(TextureTarget, GL_TEXTURE_WRAP_T, GL_CLAMP);
#endif
    glTexParameteri(TextureTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(TextureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(TextureTarget, 0, TextureInternal, width, height, 0, 
                 TextureFormat, TextureType, 0);
    glBindTexture(TextureTarget, 0);
}

static int SetupGraphics(unsigned int width, unsigned int height) {

    CreateTexture(width, height);

    glClearColor (0.0, 0.0, 0.0, 0.0);

    glDisable(GL_DEPTH_TEST);
    glActiveTexture(GL_TEXTURE0);
    glViewport(0, 0, width, height);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    TexCoords[3][0] = 0.0f;
    TexCoords[3][1] = 0.0f;
    TexCoords[2][0] = width;
    TexCoords[2][1] = 0.0f;
    TexCoords[1][0] = width;
    TexCoords[1][1] = height;
    TexCoords[0][0] = 0.0f;
    TexCoords[0][1] = height;

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, VertexPos);
    glClientActiveTexture(GL_TEXTURE0);
    glTexCoordPointer(2, GL_FLOAT, 0, TexCoords);
    return GL_NO_ERROR;
}

struct PixelRGBA8888 {
  unsigned char r, g, b, a;
};

struct Bitmap {
  PixelRGBA8888* pixels;
  int width;
  int height;
  
  Bitmap(int Width, int Height) {
    width = Width;
    height = Height;
    pixels = new PixelRGBA8888[Width * Height];
    if (pixels == NULL)
		throw std::runtime_error("Out of memory for pixels");
  }
  
  ~Bitmap() {
    delete[] pixels;
  }

  void draw(void) {
  	#ifndef __EMSCRIPTEN__
    glRasterPos2i(0, 0);
    glDrawPixels(width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    #else
 	glEnable( TextureTarget );
    glBindTexture( TextureTarget, TextureId );

    if(pixels) {
        glTexSubImage2D(TextureTarget, 0, 0, 0, width, height, TextureFormat, TextureType, pixels);
    }

	glBegin(GL_TRIANGLE_STRIP);
	glColor3f( 1, 1, 1 );
    glTexCoord2i( 0, 0 ); glVertex3f( 0, 0, 0 );
    glColor3f( 1, 1, 1 );
    glTexCoord2i( 0, 1 ); glVertex3f( 0, height, 0 );
    glColor3f( 1, 1, 1 );
    glTexCoord2i( 1, 0 ); glVertex3f( width, 0, 0 );
    glColor3f( 1, 1, 1 );
    glTexCoord2i( 1, 1 ); glVertex3f( width, height, 0 );
    glEnd();

    glDisable( TextureTarget );
    glBindTexture( TextureTarget, 0 );
    #endif
  }
};

class JugCLer : public OCLToy {
public:
	JugCLer() : OCLToy("JugCLer v" OCLTOYS_VERSION_MAJOR "." OCLTOYS_VERSION_MINOR " (OCLToys: http://code.google.com/p/ocltoys)") {
		millisTimerFunc = 1000.0 / 60.0; // 60Hz

		bitmap = NULL;
		scene = NULL;
		animCamera = true;
		pixelsBuff = NULL;
		sceneBuff = NULL;

		frameSec = 0.0;
	}

	virtual ~JugCLer() {
		FreeBuffers();
		delete bitmap;
		delete scene;
	}

protected:
	boost::program_options::options_description GetOptionsDescriction() {
		boost::program_options::options_description opts("JugCLer options");

		opts.add_options()
			("kernel,k", boost::program_options::value<std::string>()->default_value("trace.cl"),
				"OpenCL kernel file name")
			("workgroupsize,z", boost::program_options::value<size_t>(), "OpenCL workgroup size");

		return opts;
	}

	virtual int RunToy() {
		// set up buffers
		bitmap = new Bitmap(windowWidth, windowHeight);
		scene = new Scene;

		// set up scene
		setupAnim(scene, windowWidth, windowHeight);

		SetupGraphics( windowWidth, windowHeight);

		SetUpOpenCL();

		glutMainLoop();

		return EXIT_SUCCESS;
	}

	//--------------------------------------------------------------------------
	// GLUT related code
	//--------------------------------------------------------------------------

	virtual void DisplayCallBack() {
		ComputeImage();
		bitmap->draw();

		#ifndef __EMSCRIPTEN__
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glColor4f(0.f, 0.f, 0.f, 0.8f);
		glRecti(0, windowHeight - 30,
				windowWidth - 1, windowHeight - 1);
		glRecti(0, 0, windowWidth - 1, 18);
		glDisable(GL_BLEND);

		// Title
		glColor3f(1.f, 1.f, 1.f);
		glRasterPos2i(4, windowHeight - 10);
		PrintString(GLUT_BITMAP_8_BY_13, "JugCLer 1.0 by Holger Bettag (hobold@vectorizer.org)");
		glRasterPos2i(4, windowHeight - 25);
		PrintString(GLUT_BITMAP_8_BY_13, "Heavily inspired by Michael Birken's"
				" reverse engineering of Eric Graham's original Amiga"
				" juggler demo");
		#endif
		// Caption line 0
		const std::string captionString = boost::str(boost::format("[60Hz screen refresh][No-Vsync %.1f Frame/sec][%.1fM Sample/sec]") %
				frameSec % (frameSec * windowWidth * windowHeight / 1000000.0));
		
		#ifndef __EMSCRIPTEN__
		glColor3f(1.f, 1.f, 1.f);
		glRasterPos2i(4, 5);
		#endif

		if (printCaption)
			PrintString(GLUT_BITMAP_8_BY_13, captionString.c_str());
	

		if (printHelp) {
			glPushMatrix();
			glLoadIdentity();
			glOrtho(-.5f, windowWidth - .5f,
				-.5f, windowHeight - .5f, -1.f, 1.f);

			PrintHelp();

			glPopMatrix();

			#ifdef __EMSCRIPTEN__
				printHelp = 1-printHelp;
			#endif
		}
		

		glutSwapBuffers();
	}

	//--------------------------------------------------------------------------
	// GLUT call backs
	//--------------------------------------------------------------------------

	virtual void ReshapeCallBack(int newWidth, int newHeight) {
		windowWidth = newWidth;
		windowHeight = newHeight;

		glViewport(0, 0, windowWidth, windowHeight);
		glLoadIdentity();
		glOrtho(-.5f, windowWidth - .5f,
				-.5f, windowHeight - .5f, -1.f, 1.f);

		delete bitmap;
		bitmap = new Bitmap(windowWidth, windowHeight);
		const unsigned int pixelCount = windowWidth * windowHeight;
		AllocOCLBufferWO(0, &pixelsBuff, pixelCount * sizeof(PixelRGBA8888), "PixelsBuffer");
		kernelsJugCLer.setArg(1, *pixelsBuff);

		setupAnim(scene, windowWidth, windowHeight);

		glutPostRedisplay();
	}

#define MOVE_STEP 0.4f
#define ROTATE_STEP (2.f * ((float)M_PI) / 180.f)
	virtual void KeyCallBack(unsigned char key, int x, int y) {
		bool needRedisplay = true;

		switch (key) {
			case 'p': {
				// Write image to PPM file
				std::ofstream f("image.ppm", std::ofstream::trunc);
				if (!f.good()) {
					OCLTOY_LOG("Failed to open image file: image.ppm");
				} else {
					f << "P3" << std::endl;
					f << windowWidth << " " << windowHeight << std::endl;
					f << "255" << std::endl;

					for (int y = windowHeight - 1; y >= 0; --y) {
						const PixelRGBA8888 *p = &bitmap->pixels[y * windowWidth];
						for (int x = 0; x < windowWidth; ++x, p++) {
							const std::string r = boost::lexical_cast<std::string>((unsigned int)p->r);
							const std::string g = boost::lexical_cast<std::string>((unsigned int)p->g);
							const std::string b = boost::lexical_cast<std::string>((unsigned int)p->b);
							f << r << " " << g << " " << b << std::endl;
						}
					}
				}
				f.close();
				OCLTOY_LOG("Saved framebuffer in image.ppm");

				needRedisplay = false;
				break;
			}
			case 27: // Escape key
			case 'q':
			case 'Q':
				OCLTOY_LOG("Done");

				exit(EXIT_SUCCESS);
				break;
			case ' ': // Restart rendering
				animCamera = true;
				sceneTimeOffset = WallClockTime();
				setupAnim(scene, windowWidth, windowHeight);
				break;
			case 'h':
				printHelp = (!printHelp);
				break;
			case 'c':
				printCaption = (!printCaption);
				break;						
			case 'a': {
				animCamera = false;
				cl_float3 dir = scene->cam.viewRight;
				vecNormalize(dir);
				vecScale(dir, -MOVE_STEP);
				camMove(scene->cam, dir);
				break;
			}
			case 'd': {
				animCamera = false;
				cl_float3 dir = scene->cam.viewRight;
				vecNormalize(dir);
				vecScale(dir, MOVE_STEP);
				camMove(scene->cam, dir);
				break;
			}
			case 'w': {
				animCamera = false;
				cl_float3 dir = scene->cam.viewCenter;
				vecSub(dir, scene->cam.eye);
				vecNormalize(dir);
				vecScale(dir, MOVE_STEP);
				camMove(scene->cam, dir);
				break;
			}
			case 's': {
				animCamera = false;
				cl_float3 dir = scene->cam.viewCenter;
				vecSub(dir, scene->cam.eye);
				vecNormalize(dir);
				vecScale(dir, -MOVE_STEP);
				camMove(scene->cam, dir);
				break;
			}
			case 'r': {
				animCamera = false;
				cl_float3 dir;
				vecInit(dir, 0.f, MOVE_STEP, 0.f);
				camMove(scene->cam, dir);
				break;
			}
			case 'f': {
				animCamera = false;
				cl_float3 dir;
				vecInit(dir, 0.f, -MOVE_STEP, 0.f);
				camMove(scene->cam, dir);
				break;
			}
			default:
				needRedisplay = false;
				break;
		}

		if (needRedisplay)
			glutPostRedisplay();
	}

	void SpecialCallBack(int key, int x, int y) {
		bool needRedisplay = true;

        switch (key) {
			case GLUT_KEY_LEFT: {
				animCamera = false;
				cl_float3 t = scene->cam.viewCenter;
				vecSub(t,  scene->cam.eye);
				t.s[0] = t.s[0] * cosf(-ROTATE_STEP) - t.s[2] * sinf(-ROTATE_STEP);
				t.s[2] = t.s[0] * sinf(-ROTATE_STEP) + t.s[2] * cosf(-ROTATE_STEP);
				vecAdd(t, scene->cam.eye);
				camLookAt(scene->cam, t);
				break;
			}
			case GLUT_KEY_RIGHT: {
				animCamera = false;
				cl_float3 t = scene->cam.viewCenter;
				vecSub(t,  scene->cam.eye);
				t.s[0] = t.s[0] * cosf(ROTATE_STEP) - t.s[2] * sinf(ROTATE_STEP);
				t.s[2] = t.s[0] * sinf(ROTATE_STEP) + t.s[2] * cosf(ROTATE_STEP);
				vecAdd(t, scene->cam.eye);
				camLookAt(scene->cam, t);
				break;
			}
			case GLUT_KEY_PAGE_UP: {
				animCamera = false;
				cl_float3 t;
				vecInit(t, 0.f, MOVE_STEP / 4.f, 0.f);
				vecAdd(scene->cam.viewCenter, t);
				camUpdate(scene->cam);
				break;
			}
			case GLUT_KEY_PAGE_DOWN: {
				animCamera = false;
				cl_float3 t;
				vecInit(t, 0.f, -MOVE_STEP / 4.f, 0.f);
				vecAdd(scene->cam.viewCenter, t);
				camUpdate(scene->cam);
				break;
			}
			default:
				needRedisplay = false;
				break;
		}

		if (needRedisplay)
			glutPostRedisplay();
	}

	void TimerCallBack(int id) {
		animatePositions(scene, animCamera);

		glutPostRedisplay();

		// Refresh the timer
		glutTimerFunc(millisTimerFunc, &OCLToy::GlutTimerFunc, 0);
	}

	//--------------------------------------------------------------------------
	// OpenCL related code
	//--------------------------------------------------------------------------

	virtual unsigned int GetMaxDeviceCountSupported() const {
		return 1;
	}

private:
	// compute and draw image
	void ComputeImage() {
		const double t0 = WallClockTime();

		// copy scene from host to device
		cl::CommandQueue &oclQueue = deviceQueues[0];
		oclQueue.enqueueWriteBuffer(*sceneBuff,
				CL_FALSE,
				0,
				sceneBuff->getInfo<CL_MEM_SIZE>(),
				scene);

		size_t globalThreads = windowWidth * windowHeight;
		if (globalThreads % kernelsWorkGroupSize != 0)
			globalThreads = (globalThreads / kernelsWorkGroupSize + 1) * kernelsWorkGroupSize;

		// Enqueue a kernel run
		oclQueue.enqueueNDRangeKernel(kernelsJugCLer, cl::NullRange,
				cl::NDRange(globalThreads), cl::NDRange(kernelsWorkGroupSize));

		// Read back the result
		oclQueue.enqueueReadBuffer(
				*(pixelsBuff),
				CL_FALSE,
				0,
				pixelsBuff->getInfo<CL_MEM_SIZE>(),
				bitmap->pixels);
		oclQueue.finish();
		const double t1 = WallClockTime();

		// A simple trick to smooth sample/sec value
		const double k = 0.01;
		frameSec = (1.0 - k) * frameSec + k * (1.0 / (t1 -t0));
	}

	void SetUpOpenCL() {
		//----------------------------------------------------------------------
		// Compile kernel
		//----------------------------------------------------------------------

		const std::string &kernelFileName = commandLineOpts["kernel"].as<std::string>();
		OCLTOY_LOG("Compile OpenCL kernel: " << kernelFileName);

		// Read the kernel
		const std::string kernelSource = ReadSources(kernelFileName);

		// Create the kernel program
		cl::Device &oclDevice = selectedDevices[0];
		cl::Context &oclContext = deviceContexts[0];

    	const char *charSrc = kernelSource.c_str();
		cl::Program::Sources sources(1, std::make_pair(charSrc, kernelSource.length()));    	
		cl::Program program = cl::Program(oclContext, sources);
		try {
			VECTOR_CLASS<cl::Device> buildDevice;
			buildDevice.push_back(oclDevice);
			program.build(buildDevice);
		} catch (cl::Error err) {
			cl::STRING_CLASS strError = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(oclDevice);
			OCLTOY_LOG("Kernel compilation error:\n" << strError.c_str());

			throw err;
		}

		kernelsJugCLer = cl::Kernel(program, "render_gpu");
		kernelsJugCLer.getWorkGroupInfo<size_t>(oclDevice, CL_KERNEL_WORK_GROUP_SIZE, &kernelsWorkGroupSize);
		if (commandLineOpts.count("workgroupsize"))
			kernelsWorkGroupSize = commandLineOpts["workgroupsize"].as<size_t>();
		OCLTOY_LOG("Using workgroup size: " << kernelsWorkGroupSize);

		//----------------------------------------------------------------------
		// Allocate buffer
		//----------------------------------------------------------------------

		AllocateBuffers();

		//----------------------------------------------------------------------
		// Set kernel arguments
		//----------------------------------------------------------------------

		kernelsJugCLer.setArg(0, *sceneBuff);
		kernelsJugCLer.setArg(1, *pixelsBuff);
	}

	void FreeBuffers() {
		FreeOCLBuffer(0, &pixelsBuff);
		FreeOCLBuffer(0, &sceneBuff);
	}

	void AllocateBuffers() {
		// Allocate the pixels buffer
		const unsigned int pixelCount = windowWidth * windowHeight;
		AllocOCLBufferWO(0, &pixelsBuff, pixelCount * sizeof(PixelRGBA8888), "PixelsBuffer");

		// Allocate the scene buffer
		AllocOCLBufferRO(0, &sceneBuff, scene, sizeof(Scene), "SceneBuffer");
	}

	void PrintHelp() {
		#ifndef __EMSCRIPTEN__
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glColor4f(0.f, 0.f, 0.5f, 0.5f);
		glRecti(50, 50, windowWidth - 50, windowHeight - 50);

		glColor3f(1.f, 1.f, 1.f);
		int fontOffset = windowHeight - 50 - 20;
		glRasterPos2i((windowWidth - glutBitmapLength(GLUT_BITMAP_9_BY_15, (unsigned char *)"Help & Devices")) / 2, fontOffset);
		#else
		int fontOffset = 0;
		#endif
		PrintString(GLUT_BITMAP_9_BY_15, "Help & Devices");
        // Help
		fontOffset -= 30;
		PrintHelpString(60, fontOffset, "h / c", "toggle Help / toggle Caption");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "arrow Keys", "rotate camera left/right");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "a and d", "move camera left and right");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "w and s", "move camera forward and backward");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "r and f", "move camera up and down");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "PageUp and PageDown", "move camera target up and down");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "p", "save image.ppm");
		fontOffset -= 17;
		PrintHelpString(60, fontOffset, "space", "restart animation");

		#ifndef __EMSCRIPTEN__
		glDisable(GL_BLEND);
		#endif
	}

	Bitmap *bitmap; // image for display
	Scene *scene;
	bool animCamera;

	cl::Buffer *pixelsBuff;
	cl::Buffer *sceneBuff;

	cl::Kernel kernelsJugCLer;
	size_t kernelsWorkGroupSize;
	
	double frameSec;
};

int main(int argc, char **argv) {
	JugCLer toy;
	return toy.Run(argc, argv);
}
