
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "..\usr\include\GL\freeglut.h"
#include <stdio.h>
#include <time.h>
#include <math.h>

//�ݹ� �Լ�
void Render();
void Reshape(int w, int h);
void Timer(int id);

//����� ���� �Լ�
void CreateJuliaSet();

#define TILE_WIDTH 32
const int Dim = 1024;
unsigned char Image[Dim*Dim * 3];
unsigned char *DevImage;
float theta = 0.0;

int main(int argc, char **argv)
{
	//GLUT �ʱ�ȭ
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	//������ ũ�� ���� �� ����
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Julia Set(GPU)");

	//�ݹ� �Լ� ���
	glutDisplayFunc(Render);
	glutReshapeFunc(Reshape);
	glutTimerFunc(1, Timer, 0);

	cudaSetDevice(0);
	cudaMalloc((void **)&DevImage, sizeof(unsigned char) * Dim * Dim * 3);

	//�̺�Ʈ ó�� ���� ����
	glutMainLoop();

	cudaFree(DevImage);
	cudaDeviceReset();
	return 0;
}

void Render()
{
	//�ȼ� ����(���)�� ������� �ʱ�ȭ�Ѵ�.
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT);

	//Julia ���� ã�� �ȼ� ���۸� ä���.
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