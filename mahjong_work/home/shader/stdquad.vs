uniform highp mat4 ModelViewProj;

attribute vec4 fx_gl_Vertex;
attribute vec4 fx_gl_Color0;
attribute vec2 fx_gl_Tex0;

varying lowp vec4 xlv_COLOR;
varying mediump vec2 xlv_TEXCOORD0;
varying highp vec3 vPosition;

void main() {
    gl_Position = fx_gl_Vertex * ModelViewProj;
    xlv_COLOR = fx_gl_Color0;
    xlv_TEXCOORD0 = fx_gl_Tex0;
    vPosition = gl_Position.xyz / gl_Position.w;
}
