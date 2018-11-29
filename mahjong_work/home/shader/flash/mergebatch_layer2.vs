
float4x4 ModelViewProj : ModelViewProjection;

void main(float4 position : POSITION,
		float4 diffuse : COLOR,
		float2 tex : TEXCOORD0,

             out float4 oPosition : POSITION,
             out float4 oDiffuse : COLOR,
             out float2 oTex : TEXCOORD0                         
               
         )
{
  oPosition = mul(ModelViewProj,position);
  oDiffuse = diffuse;
  oTex = tex;
}