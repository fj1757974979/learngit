
#line 4
const highp int MAX_MATRICES = 60;
uniform highp mat4 BlendMatrixArray[60];
uniform highp mat4 ModelViewProj;
#line 9
#line 34
void calc_skin_position_normal( in highp vec3 pos, in highp vec3 nor, in highp ivec4 blendindices, in highp vec4 blendweight, out highp vec3 oPos, out highp vec3 oNormal );
void xlat_main( in highp vec3 pos, in highp vec4 bweights, in highp vec4 bindices, in highp vec3 nor, in highp vec4 col, in highp vec2 tex, out highp vec4 oPosition, out highp vec4 oColor, out highp vec2 oTex );
#line 9
void calc_skin_position_normal( in highp vec3 pos, in highp vec3 nor, in highp ivec4 blendindices, in highp vec4 blendweight, out highp vec3 oPos, out highp vec3 oNormal ) {
    oPos = vec3( 0.0);
    oNormal = vec3( 0.0);
    #line 14
    highp int i = 0;
    for ( ; (i < 4); (i++)) {
        if ((blendindices[i] == 255)){
            break;
        }
        oPos += vec3( ((vec4( pos, 1.0) * BlendMatrixArray[blendindices[i]]) * blendweight[i]));
        #line 18
        oNormal += vec3( ((vec4( nor, 1.0) * BlendMatrixArray[blendindices[i]]) * blendweight[i]));
    }
}
#line 34
void xlat_main( in highp vec3 pos, in highp vec4 bweights, in highp vec4 bindices, in highp vec3 nor, in highp vec4 col, in highp vec2 tex, out highp vec4 oPosition, out highp vec4 oColor, out highp vec2 oTex ) {
    highp vec3 skinPos, skinNormal;
    #line 38
    calc_skin_position_normal( pos, nor, ivec4(bindices), bweights, skinPos, skinNormal);
    oPosition = (vec4( skinPos, 1.0) * ModelViewProj);
    oColor = col;
    oTex = tex;
}
attribute vec3 fx_gl_Vertex;
attribute vec4 fx_gl_BlendWeight;
attribute vec4 fx_gl_BlendIndex;
attribute vec3 fx_gl_Normal;
attribute vec4 fx_gl_Color0;
attribute vec2 fx_gl_Tex0;
varying highp vec4 xlv_COLOR;
varying highp vec2 xlv_TEXCOORD0;
void main() {
    highp vec4 xlt_oPosition;
    highp vec4 xlt_oColor;
    highp vec2 xlt_oTex;
    xlat_main( vec3(fx_gl_Vertex), vec4(fx_gl_BlendWeight), vec4(fx_gl_BlendIndex), vec3(fx_gl_Normal), vec4(fx_gl_Color0), vec2(fx_gl_Tex0), xlt_oPosition, xlt_oColor, xlt_oTex);
    gl_Position = vec4(xlt_oPosition);
    xlv_COLOR = vec4(xlt_oColor);
    xlv_TEXCOORD0 = vec2(xlt_oTex);
}
