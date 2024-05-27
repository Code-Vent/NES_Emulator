#include<Windows.h>
//#include<GL/GL.h>

#include<iostream>
#include"memory_mapped.h"
#include"renderer2D.h"
#include"win.h"
#include"cpu.h"
#include"nes.h"
#include"../Dependencies/GLFW/glfw3.h"

#define FREEGLUT_STATIC
#define _LIB
#define FREEGLUT_LIB_PRAGMAS 0
#include"../Dependencies/freeglut/freeglut.h"

using namespace std;

constexpr int SCREEN_HEIGHT = 400;
constexpr int SCREEN_WIDTH = 640;


void error_callback(int error, const char* description) {
	fprintf(stderr, "Error: %s\n", description);
}

int main(void) {
	glfwSetErrorCallback(error_callback);
	if (!glfwInit()) {
		exit(EXIT_FAILURE);
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "NES Emulator", NULL, NULL);
	if (!window) {
		glfwTerminate();
		exit(EXIT_FAILURE);
	}

	uint8_t* pixels_buffer = new uint8_t[sizeof(COLOREF) * SCREEN_HEIGHT * SCREEN_WIDTH];

	//Copy the Window parameters to the beginning of screen buffer
	//for the low level driver
	WindowParams* p = reinterpret_cast<WindowParams*>(pixels_buffer);
	p->handle = window;
	p->frame_width = SCREEN_WIDTH;
	p->frame_height = SCREEN_HEIGHT;

	WindowDriver win_driver;

	MemoryMappedDevice<COLOREF> screen(pixels_buffer, SCREEN_HEIGHT * SCREEN_WIDTH, &win_driver);
	Renderer2D<COLOREF> renderer(screen, SCREEN_WIDTH, SCREEN_HEIGHT);
	screen.get_device()->configure();
	
	{
		MemType* mem = new MemType[NES::mem_size()];
		NES nes(mem);
		delete[]mem;
	}

	while (!glfwWindowShouldClose(window)) {
		renderer.red_screen();
		glfwSwapBuffers(window);
		renderer.blue_screen();
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	glfwDestroyWindow(window);
	glfwTerminate();
	delete[] pixels_buffer;
	exit(EXIT_FAILURE);
}