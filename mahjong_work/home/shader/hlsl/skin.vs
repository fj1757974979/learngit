

static const int MAX_MATRICES = 60;
float4x4 BlendMatrixArray[MAX_MATRICES];
float4x4 ModelViewProj;

void calc_skin_position_normal(float3 pos, float3 nor,int4 blendindices,float4 blendweight,
				out float3 oPos, out float3 oNormal)
{
	oPos = 0.0f;
	oNormal = 0.0f;
	
	for (int i=0; i<4; i++)
	{
		if(blendindices[i]==255) break;
		oPos += mul(float4(pos,1), BlendMatrixArray[blendindices[i]]) * blendweight[i];
		oNormal += mul(float4(nor,1), BlendMatrixArray[blendindices[i]]) * blendweight[i];		
	}	
}


void main(float3 pos : POSITION,
	  	float4 bweights	: BLENDWEIGHT,
		float4 bindices	: BLENDINDICES,
		float3 nor	: NORMAL,
		float4 col	: COLOR,
		float2 tex	: TEXCOORD0,

             out float4 oPosition : POSITION,
             out float4 oColor : COLOR,
             out float2 oTex : TEXCOORD0                         
               
         )
{

	float3 skinPos, skinNormal;
	calc_skin_position_normal(pos, nor, (int4)bindices, bweights, skinPos, skinNormal);
	oPosition = mul(float4(skinPos,1), ModelViewProj);
	oColor = col;
	oTex = tex;
}