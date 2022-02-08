#include <stdlib.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <vector>
#include <math.h>
#include <time.h>//�� ���
#include "..\usr\include\GL\freeglut.h"

using namespace std;

#define TILE_WIDTH 12
const int Dim = 972;//3�� 5�� X 4 
unsigned char Image[Dim * Dim * 3];
unsigned char* Dev_Image;

int ManipulateMode = 0;
float Angle = 0.0;
//Ȯ�� ��Ҹ� ���� ����
int aa = 1;
int bb = 1;

//�ּ� �簢�� ũ��� ����
int limit;
//��ȭ�ϴ� ������ ��� ������ ���� ����
int Flow;

float Theta = 0.0;
int MaxIter = 256;
int StartPt[2];
float Zoom = -50.0;


vector <vector <int> > a;

unsigned char ColorTable[18];

// �ݹ� �Լ�
void Render();
void Reshape(int w, int h);
void Timer(int id);
void MouseWheel(int button, int dir, int x, int y);
void Keyboard(unsigned char key, int x, int y);


// ����� ���� �Լ�
void CreateNemo();
__device__ void ColorNemo(int yy, int flow, int& r, int& g, int& b);
__global__ void NemoKernel(unsigned char* d, int li, int flow);
__int64 GetMicroSecond();


int main(int argc, char** argv)
{
	limit = Dim;
	// GLUT �ʱ�ȭ
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	// ������ ũ�� ���� �� ����
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Sierpinski carpet(GPU)");
	cudaMalloc((void**)&Dev_Image, 3 * Dim * Dim * sizeof(unsigned char));

	// �ݹ� �Լ� ���
	glutDisplayFunc(Render);
	glutMouseWheelFunc(MouseWheel);
	glutKeyboardFunc(Keyboard);
	glutReshapeFunc(Reshape);
	glutTimerFunc(1, Timer, 0);



	cudaSetDevice(0);

	// �̺�Ʈ ó�� ���� ����
	glutMainLoop();

	cudaFree(Dev_Image);
	cudaDeviceReset();
	return 0;
}

void Render()
{
	// �ȼ� ����(���) ������� �ʱ�ȭ
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT);
	CreateNemo();
	glDrawPixels(Dim, Dim, GL_RGB, GL_UNSIGNED_BYTE, Image);

	glFinish();
}

void Timer(int id)
{
	// Render �Լ��� ȣ���ϰ�, ���� Ÿ�̸Ӹ� �����Ѵ�.
	Flow += 3;//y�࿡ ���� ���� �����ϱ� ���� ����
	if (Flow > 972) {
		Flow = 0; //Dimũ�� �ʰ� �� �ٽ� ó������ �ǵ��� ����.
	}
	glutPostRedisplay();
	glutTimerFunc(1, Timer, 0);
}


__int64 GetMicroSecond()//�ð�����
{
	LARGE_INTEGER frequency;
	LARGE_INTEGER now;

	if (!QueryPerformanceFrequency(&frequency))
		return (__int64)GetTickCount();

	if (!QueryPerformanceCounter(&now))
		return (__int64)GetTickCount();

	return ((now.QuadPart) / (frequency.QuadPart / 1000000));
}


void MouseWheel(int button, int dir, int x, int y)//ȭ�� Ȯ��, ��� �Լ�
{
	if (dir > 0)
	{
		aa += 1;
		bb += 1;
		glPixelZoom(aa, bb);
	}
	else
	{

		aa -= 1;
		bb -= 1;
		if (aa < 1 || bb < 1)
		{
			aa = 1;
			bb = 1;
		}
		glPixelZoom(aa, bb);
	}
	glutPostRedisplay();
}

void Keyboard(unsigned char key, int x, int y)//Ű���� ���� �Լ�
{
	// ESC Ű�� ������ �޽� ����Ʈ�� �޸𸮿��� �����ϰ� �����Ѵ�.
	if (key == 27)
		exit(0);

	//d Ű�� ������ �ܰ� ������
	if (key == 100)
	{
		if (limit >4)
		{
			limit = limit / 3;
		}
		glutPostRedisplay();//�ٽ� �׸���
	}
	//aŰ�� ������ �ܰ� ���߱�
	if (key == 97)
	{
		if (limit < Dim)
			limit = limit * 3;
		glutPostRedisplay();//�ٽ� �׸���
	}

}

void Reshape(int w, int h)
{
	glViewport(0, 0, w, h);
}



void CreateNemo() {

	dim3 gridDim(Dim / TILE_WIDTH, Dim / TILE_WIDTH);//�׸��� ũ�� ����
	dim3 blockDim(TILE_WIDTH, TILE_WIDTH);//��� ũ�� ����
	__int64 st = GetMicroSecond();

	NemoKernel << <gridDim, blockDim >> > (Dev_Image, limit, Flow);//Ŀ�� �Լ� ȣ��
	cudaDeviceSynchronize();//����ȭ
	cudaMemcpy(Image, Dev_Image, Dim * Dim * 3 * sizeof(unsigned char), cudaMemcpyDeviceToHost);//����̽�->ȣ��Ʈ�� �̹����迭 ����

	printf("Elapsed time = %u micro sec.\n", GetMicroSecond() - st);//����ð� ���

}
__device__ void ColorNemo(int yy, int flow, int& r, int& g, int& b)/*�帣�� ������ ��� ������ ���� �Լ�*/
{
	int ColorTable[18];//�� 6�� ������ RGB�� ����
					   //����
	ColorTable[0] = 225;//R
	ColorTable[1] = 102;//G
	ColorTable[2] = 99;//B
					   //�Ķ�
	ColorTable[3] = 158;
	ColorTable[4] = 193;
	ColorTable[5] = 207;
	//�ʷ�
	ColorTable[6] = 158;
	ColorTable[7] = 224;
	ColorTable[8] = 158;
	//���
	ColorTable[9] = 253;
	ColorTable[10] = 253;
	ColorTable[11] = 151;
	//��Ȳ
	ColorTable[12] = 254;
	ColorTable[13] = 177;
	ColorTable[14] = 68;
	//����
	ColorTable[15] = 204;
	ColorTable[16] = 153;
	ColorTable[17] = 201;

	float t = yy + flow;//t���� �� �������� y��ǥ�� �뺯�ϴ� ������ ����ؼ� ���ϴ� y��ǥ�� ������ �ݿ��Ѵ�.
	if (t > 971) {//t�� Dim��ŭ �̵��Ǿ��� ��
		t = flow - 971 + yy;//DIm�� �ʰ��ϸ� 0~5���� ������ ��ȯ���� ���ϹǷ� �ٽ� ó������ ���ư���.
	}
	t = t * 0.005;//0~5�� ������ ���
				  //t���� ���� �� ������ ������ ������ ����
	if (t >= 0 && t < 1) {
		r = (int)(ColorTable[0] * (1 - t) + t * ColorTable[3]);
		g = (int)(ColorTable[1] * (1 - t) + t * ColorTable[4]);
		b = (int)(ColorTable[2] * (1 - t) + t * ColorTable[5]);
	}
	else if (t >= 1 && t < 2) {
		t = t - 1;
		r = (int)(ColorTable[3] * (1 - t) + t * ColorTable[6]);
		g = (int)(ColorTable[4] * (1 - t) + t * ColorTable[7]);
		b = (int)(ColorTable[5] * (1 - t) + t * ColorTable[8]);
	}
	else if (t >= 2 && t < 3) {
		t = t - 2;
		r = (int)(ColorTable[6] * (1 - t) + t * ColorTable[9]);
		g = (int)(ColorTable[7] * (1 - t) + t * ColorTable[10]);
		b = (int)(ColorTable[8] * (1 - t) + t * ColorTable[11]);
	}
	else if (t >= 3 && t < 4) {
		t = t - 3;
		r = (int)(ColorTable[9] * (1 - t) + t * ColorTable[12]);
		g = (int)(ColorTable[10] * (1 - t) + t * ColorTable[13]);
		b = (int)(ColorTable[11] * (1 - t) + t * ColorTable[14]);
	}
	else if (t >= 4 && t < 5) {
		t = t - 4;
		r = (int)(ColorTable[12] * (1 - t) + t * ColorTable[15]);
		g = (int)(ColorTable[13] * (1 - t) + t * ColorTable[16]);
		b = (int)(ColorTable[14] * (1 - t) + t * ColorTable[17]);
	}
	else {
		r = 255;
		g = 255;
		b = 255;
	}
}



__global__ void NemoKernel(unsigned char* d, int li, int flow)//�ÿ����ɽ�Ű �簢�� ���� �Լ�
{
	int x = blockIdx.x * TILE_WIDTH + threadIdx.x;
	int y = blockIdx.y * TILE_WIDTH + threadIdx.y;
	int size = Dim;



	if ((x < Dim) && (y < Dim))//Color Nemo�� �̿��� ���� ä���
	{
		int rr, gg, bb;
		ColorNemo(y, flow, rr, gg, bb);
		int offset = (y * Dim + x) * 3;
		d[offset] = rr;
		d[offset + 1] = gg;
		d[offset + 2] = bb;
	}
	while (size >= li)//�� �ܰ踶��(li=limit=4=�ּ� �簢�� �Ѻ��� �ȼ� ��)
	{
		size = size / 3;//�簢���� �Ѻ��� 3����Ѵ�. 
		if (size == 1) {//�ִ� �ܰ��� ����̴�. �ּ� �簢���� �Ѻ��� 3�� ����� �ƴϹǷ� 3����� �Ұ����� ���� ����� �ش�.
			if ((((x / size) % 4 == 1) || ((x / size) % 4 == 2)) && (((y / size) % 4 == 1) || ((y / size) % 4 == 2)))/*3��е� �簢���� �� �� �߾�
																													 �� ��ġ�� �簢���� ä��� �������� ���*/
			{
				int offset2 = (x + y * Dim) * 3;
				d[offset2] = 235;
				d[offset2 + 1] = 230;
				d[offset2 + 2] = 204;
			}
		}
		else if (((x / size) % 3 == 1) && ((y / size) % 3 == 1)) {/*�ִ� �ܰ踦 ������ ����̴�. ���� ������ �ε���(��ġ)�� size�� ������ 3����
																  �������� ���� �������� 1�� ������� ���߾��� �簢���� ä��� �������̴�*/
			int offset2 = (x + y * Dim) * 3;
			d[offset2] = 235;
			d[offset2 + 1] = 230;
			d[offset2 + 2] = 204;

		}
	}
}