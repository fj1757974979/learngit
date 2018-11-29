#version 120

#line 3
uniform mat4 ModelViewProj;
#line 13
void xlat_main( in vec4 position, in vec4 diffuse, in vec2 tex, out vec4 oPosition, out vec4 oDiffuse, out vec2 oTex );
#line 13
void xlat_main( in vec4 position, in vec4 diffuse, in vec2 tex, out vec4 oPosition, out vec4 oDiffuse, out vec2 oTex ) {
    oPosition = (ModelViewProj * position);
    oDiffuse = diffuse;
    #line 17
    oTex = tex;
}
attribute vec4 fx_gl_Vertex;
attribute vec4 fx_gl_Color0;
attribute vec2 fx_gl_Tex0;
varying vec4 xlv_COLOR;
varying vec2 xlv_TEXCOORD0;
void main() {
    vec4 xlt_oPosition;
    vec4 xlt_oDiffuse;
    vec2 xlt_oTex;
    xlat_main( vec4(fx_gl_Vertex), vec4(fx_gl_Color0), vec2(fx_gl_Tex0), xlt_oPosition, xlt_oDiffuse, xlt_oTex);
    gl_Position = vec4(xlt_oPosition);
    xlv_COLOR = vec4(xlt_oDiffuse);
    xlv_TEXCOORD0 = vec2(xlt_oTex);
}
