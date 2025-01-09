Shader "DopeRP/Shaders/Empty"
{
	Properties
	{
	}

	SubShader
	{
		
		
		Pass {
			
					Tags { "RenderType"="Opaque" "LightMode"="Empty"}

			Blend Zero One
			ZWrite off
			Cull Back
			

		}

	}
}