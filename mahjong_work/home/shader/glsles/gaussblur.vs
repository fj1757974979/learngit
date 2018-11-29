#define lowp

uniform lowp mat4 ModelViewProj;

attribute vec4 fx_gl_Vertex;
attribute vec4 fx_gl_Color0;
attribute vec2 fx_gl_Tex0;

varying lowp vec4 xlv_COLOR;
varying lowp vec2 xlv_TEXCOORD0;
varying lowp vec3 vPosition;
varying vec2 blurCoordinates[9];

void main() {
    gl_Position = fx_gl_Vertex * ModelViewProj;
    xlv_COLOR = fx_gl_Color0;
    xlv_TEXCOORD0 = fx_gl_Tex0;
	vPosition = gl_Position.xyz / gl_Position.w;

	lowp vec2 singleStepOffset0 = vec2(0.0005, 0.0005);
	lowp vec2 singleStepOffset1 = vec2(0.0005, -0.0005);
	lowp vec2 singleStepOffset2 = vec2(0.0005, 0);
	lowp vec2 singleStepOffset3 = vec2(0, 0.0005);
	blurCoordinates[0] = fx_gl_Tex0.xy;
	blurCoordinates[1] = fx_gl_Tex0.xy + singleStepOffset0 * 1.407333;
	blurCoordinates[2] = fx_gl_Tex0.xy - singleStepOffset0 * 1.407333;
	blurCoordinates[3] = fx_gl_Tex0.xy + singleStepOffset1 * 1.407333;
	blurCoordinates[4] = fx_gl_Tex0.xy - singleStepOffset1 * 1.407333;
	blurCoordinates[5] = fx_gl_Tex0.xy + singleStepOffset2 * 1.407333;
	blurCoordinates[6] = fx_gl_Tex0.xy - singleStepOffset2 * 1.407333;
	blurCoordinates[7] = fx_gl_Tex0.xy + singleStepOffset3 * 1.407333;
	blurCoordinates[8] = fx_gl_Tex0.xy - singleStepOffset3 * 1.407333;
}
