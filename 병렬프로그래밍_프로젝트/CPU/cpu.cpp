#include <stdlib.h>
#include<iostream>
#include <vector>
#include <math.h>
#include <time.h>//�� ���
#include "..\usr\include\GL\freeglut.h"

using namespace std;
int StartPt[2];
float Zoom = -50.0;
int ManipulateMode = 0;
int aa = 1;
int bb = 1;//Ȯ�� ��Ҹ� ���� ����

__int64 GetMicroSecond();

const int Dim = 972;//3�� 5�� ���ϱ� 4->�ּ� �ȼ��� 4x4�� �ǰ�, �ܰ�� �⺻ �ܰ���� ���ؼ� �� 6�ܰ谡 �ȴ�.
int limit = Dim;//�ܰ踦 ���� �� ����. Ű���� �̺�Ʈ�� ���� �����ϴ�.

unsigned char Image[Dim * Dim * 3];//�̹��� �迭 ����



vector <vector <int> > a;// �ܰ躰�� ��������� �簢������ ���� �� ������ ������ ������ ����.
//�� ���ʹ� (x��ǥ, y��ǥ, size ũ��)�� �迭�� �̷���� �ִ�.

// �ݹ� �Լ�
void Render();
void Reshape(int w, int h);
void MouseWheel(int button, int dir, int x, int y);
void Keyboard(unsigned char key, int x, int y);


// ����� ���� �Լ�
void Nemo();//�ÿ����ɽ�Ű ī���� �������ִ� �Լ�

int main(int argc, char** argv)
{
    // GLUT �ʱ�ȭ
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB);

    // ������ ũ�� ���� �� ����
    glutInitWindowSize(Dim, Dim);
    glutCreateWindow("Sierpinski carpet");

    // �ݹ� �Լ� ���
    glutDisplayFunc(Render);
    glutMouseWheelFunc(MouseWheel);
    glutKeyboardFunc(Keyboard);
    glutReshapeFunc(Reshape);

    // �̺�Ʈ ó�� ���� ����
    glutMainLoop();

    return 0;
}

void Render()
{
    // �ȼ� ����(���) ������� �ʱ�ȭ
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    Nemo();//�ÿ����ɽ�Ű ���� �Լ��� �����Ѵ�.

    glDrawPixels(Dim, Dim, GL_RGB, GL_UNSIGNED_BYTE, Image); //�̹��� �ȼ��� �׸���.

    glFinish();

}





void MouseWheel(int button, int dir, int x, int y)
{
    if (dir > 0)
    {
        aa += 1;
        bb += 1;
        glPixelZoom(aa, bb);//���콺�� ���� ���� �����̸� Ȯ�븦 �Ѵ�.
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
        glPixelZoom(aa, bb);//���콺�� ���� �Ʒ��� �����̸� ��Ҹ� �Ѵ�.
    }
    glutPostRedisplay();//��ȭ�� �־��� ������ �ٽñ׸���.
}

void Keyboard(unsigned char key, int x, int y)
{
    // ESC Ű�� ������ �޽� ����Ʈ�� �޸𸮿��� �����ϰ� �����Ѵ�.
    if (key == 27)
        exit(0);
    //d Ű�� ������ �ܰ� ������
    if (key == 100) {
        if(limit>4)
            limit = limit / 3;
        glutPostRedisplay();//�ٽ� �׸���

    }
    //aŰ�� ������ �ܰ� ���߱�
    if (key == 97) {
        if (limit < Dim)
            limit = limit * 3;//�׻� �簢���� 3����ϸ鼭 �����ϱ� ������ �ܰ�� 3�� �ø��� ����� �Ѵ�.
        glutPostRedisplay();//�ٽ� �׸���

    }

}

void Reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void Nemo()
{
    __int64 st = GetMicroSecond();

    //������ �Ͼ�� �ʱ�ȭ ���ش�.
    for (int j = 0; j < Dim; ++j) {
        for (int i = 0; i < Dim; ++i) {
            int offset = (j * Dim + i) * 3;
            Image[offset] = 255;
            Image[offset + 1] = 255;
            Image[offset + 2] = 255;
        }
    }
    a.clear();//���͸� �ʱ�ȭ���ش�.
    //Dim�� ��������
    int size = Dim;//ó�� size�� Dim�� 972
    int x = 0;//ó�� ������ 972x972�簢���� ���� �� ��ǥ�� �������ش�.
    int y = 0;
    int max = 1;//while�� ���� for������ �ܰ������� 8�� ���ذ��鼭 �ݺ��ϰ� �ϴ� ���� 
    vector <int> vec;//������, ������� Ǫ�������� �ӽ� ����
    vec.push_back(0);
    vec.push_back(0);
    vec.push_back(size);
    a.push_back(vec);//ù��° ���� a ���Ϳ� �������ش�

    while (size >= limit) {//limit�� size���� �۰ų� ���� �����ν� ������ �� �̻����δ� �ܰ踦 �������� �ʵ��� �Ѵ�.

        size = size / 3;//��� �簢���� �� ���� ���̴� ū �簢���� �Ѻ��� ������ 3���� 1�̴�. ��� �簢���� �׸��� ���ؼ� size�� �ٿ��ش�.
        int num = a.size();//���� ������ ũ��
        for (int i = num - max; i < num; i++) {
            x = a[i][0];
            y = a[i][1];//x, y��ǥ�� ���� a������ �������� ������ش�. ������ �������� ��� �簢���� ��ĥ�ϱ� �����̴�.
            for (int j = 0; j < 9; j++) {//�Ȱ��� ũ��� 9��� �� �簢������ �ε��� ���� ��ŭ �ݺ����ش�.
                vector <int> temp;
                if (j != 4) {//��� �簢���� �ƴ϶�� ���� ������ �־��ش�.
                    //x,y�� ���ͷ� �����ؾ���
                    temp.push_back(x + (j % 3) * size);
                    temp.push_back(y + (j / 3) * size);
                    temp.push_back(size);
                    a.push_back(temp);
                }
                if (j == 4) {//��� �簢���̶�� ������ ����� ĥ���ش�.
                    int R, G, B;
                    R = rand() % 256;
                    G = rand() % 256;
                    B = rand() % 256;
                    //��� �簢���� x��ǥ= ������ x +size,
                    //��� �簢���� y��ǥ=������ y +size
                    //��� �簢���� ������ �������� �ؼ� x������ size��ŭ, y������ size��ŭ ä���ش�. 
                    for (int a = y + size; a < size * 2 + y; ++a) {
                        for (int b = x + size; b < size * 2 + x; ++b) {
                            int offset = (a * Dim + b) * 3;
                            Image[offset] = R;
                            Image[offset + 1] = G;
                            Image[offset + 2] = B;
                        }
                    }
                }
            }
            //max(8�� ����)���� Ǫ����
        }
        max = max * 8;//���� �ܰ躸�� ������ ������ �������ش�.
    }

    printf("Elapsed time = %u us\n", GetMicroSecond() - st);//�ð� ��� ��

}
__int64 GetMicroSecond()//����ũ�μ������ �ð� ���
{
    LARGE_INTEGER frequency;
    LARGE_INTEGER now;

    if (!QueryPerformanceFrequency(&frequency))
        return (__int64)GetTickCount();

    if (!QueryPerformanceCounter(&now))
        return (__int64)GetTickCount();

    return ((now.QuadPart) / (frequency.QuadPart / 1000000));
}
