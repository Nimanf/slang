//TEST(compute):COMPARE_COMPUTE:
//TEST_INPUT:ubuffer(data=[0 0 0 0], stride=4):dxbinding(0),glbinding(0),out

RWStructuredBuffer<float> outputBuffer;

__generic<T:__BuiltinFloatingPointType>
T test(T v0, T v1)
{
    return T(3.0);
}

[numthreads(4, 1, 1)]
void computeMain(uint3 dispatchThreadID : SV_DispatchThreadID)
{ 
    float outVal = test<float>(1.0, 2.0);
	outputBuffer[dispatchThreadID.x] = outVal;
}