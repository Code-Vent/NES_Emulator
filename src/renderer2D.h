#pragma once
//#include"memory_mapped_io.h"
#include"../Dependencies/freeglut/freeglut.h"
typedef uint32_t COLOREF;

template<typename P>
class Renderer2D {
public:
	Renderer2D(MemoryMappedDevice<P>&, int W, int H);
	void blue_screen();
	void red_screen();
private:
	MemoryMappedDevice<P>& pixels;
	int width;
	int height;
};

template<typename P>
Renderer2D<P>::Renderer2D(MemoryMappedDevice<P>& Pixels, int W, int H)
	:pixels(Pixels), width(W), height(H)
{
}

template<typename P>
inline void Renderer2D<P>::blue_screen()
{
	//IOUtility<P>::fill(pixels.begin(), pixels.end(), 0x00ff0000);
	glClearColor(0.0, 0.0, 1.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
}

template<typename P>
inline void Renderer2D<P>::red_screen()
{
	//IOUtility<P>::fill(pixels.begin(), pixels.end(), 0x000000ff);
	glClearColor(1.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
}
