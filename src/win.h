#pragma once
#include<Windows.h>
#include"memory_mapped.h"
#include<stdint.h>
#include"../Dependencies/GLFW/glfw3.h"
#include<iostream>
#include"../Dependencies/freeglut/freeglut.h"
using namespace std;


struct WindowParams {
	GLFWwindow* handle;
	int frame_width;
	int frame_height;
};

struct WindowDriver : public Driver<uint32_t> {
	WindowDriver() = default;
	bool configure()const override;
	void update()const override;
	void put(uint32_t pixel) const override;
	mutable WindowParams params;
	mutable int x;
	mutable int y;
};

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	switch (message) {
	case WM_DESTROY:
	{
		PostQuitMessage(0);
		return 0;
	}break;
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
}

bool WindowDriver::configure() const
{
	auto p = reinterpret_cast<WindowParams*>(registers);
	params.handle = p->handle;
	params.frame_width = p->frame_width;
	params.frame_height = p->frame_height;
	glfwMakeContextCurrent(params.handle);
	return true;
}

inline void WindowDriver::update() const
{
	x = y = 0;
}

inline void WindowDriver::put(uint32_t pixel) const
{
	if (y == params.frame_height) {
		y = 0; ++x;
	}
	//SetPixel(hdc, x, y++, pixel);
	//glC
}
