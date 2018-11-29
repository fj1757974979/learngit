
float4x4 ModelViewProj : ModelViewProjection;

void main(float4 position : POSITION,
		float4 col : COLOR,
		float2 tex : TEXCOORD0,

             out float4 oPosition : POSITION,
             out float4 oColor : COLOR,
             out float2 oTex : TEXCOORD0
               
         )
{
  oPosition = mul(position, ModelViewProj);
  oColor = col;
  oTex = tex;
}