
#line 3
uniform highp mat4 ModelViewProj;
#line 13
void xlat_main( in highp vec4 position, in highp vec4 diffuse, in highp vec2 tex, out highp vec4 oPosition, out highp vec4 oDiffuse, out highp vec2 oTex );
#line 13
void xlat_main( in highp vec4 position, in highp vec4 diffuse, in highp vec2 tex, out highp vec4 oPosition, out highp vec4 oDiffuse, out highp vec2 oTex ) {
    oPosition = (ModelViewProj * position);
    oDiffuse = diffuse;
    #line 17
    oTex = tex;
}
attribute vec4 fx_gl_Vertex;
attribute vec4 fx_gl_Color0;
attribute vec2 fx_gl_Tex0;
varying highp vec4 xlv_COLOR;
varying highp vec2 xlv_TEXCOORD0;
void main() {
    highp vec4 xlt_oPosition;
    highp vec4 xlt_oDiffuse;
    highp vec2 xlt_oTex;
    xlat_main( vec4(fx_gl_Vertex), vec4(fx_gl_Color0), vec2(fx_gl_Tex0), xlt_oPosition, xlt_oDiffuse, xlt_oTex);
    gl_Position = vec4(xlt_oPosition);
    xlv_COLOR = vec4(xlt_oDiffuse);
    xlv_TEXCOORD0 = vec2(xlt_oTex);
}
