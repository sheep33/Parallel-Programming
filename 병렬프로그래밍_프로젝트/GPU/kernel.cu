
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "..\usr\include\GL\freeglut.h"
#include <stdio.h>
#include <time.h>
#include <math.h>

//콜백 함수
void Render();
void Reshape(int w, int h);
void Timer(int id);

//사용자 정의 함수
void CreateJuliaSet();

#define TILE_WIDTH 32
const int Dim = 1024;
unsigned char Image[Dim*Dim * 3];
unsigned char *DevImage;
float theta = 0.0;

int main(int argc, char **argv)
{
	//GLUT 초기화
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	//윈도우 크기 설정 및 생성
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Julia Set(GPU)");

	//콜백 함수 등록
	glutDisplayFunc(Render);
	glutReshapeFunc(Reshape);
	glutTimerFunc(1, Timer, 0);

	cudaSetDevice(0);
	cudaMalloc((void **)&DevImage, sizeof(unsigned char) * Dim * Dim * 3);

	//이벤트 처리 루프 진입
	glutMainLoop();

	cudaFree(DevImage);
	cudaDeviceReset();
	return 0;
}

void Render()
{
	//픽셀 버퍼(배경)을 흰색으로 초기화한다.
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT);

	//Julia 집합 찾아 픽셀 버퍼를 채운다.
	CreateJuliaSet();
	glDrawPixels(Dim, Dim, GL_RGB, GL_UNSIGNED_BYTE, Image);
	glFinish();
}

void Reshape(int w, int h)
{
	glViewport(0, 0, w, h);
}

void Timer(int id)
{
	theta += 0.01;
	glutPostRedisplay();
	glutTimerFunc(1, Timer, 0);
}

void CreateJuliaSet()
{
	clock_t st = clock();
	printf("Elapsed time = %u ms\n", clock() - st);
}