//TEST(compute):COMPARE_COMPUTE_EX:-slang -compute
//TEST(compute, vulkan):COMPARE_COMPUTE_EX:-vk -compute

//TEST_INPUT:ubuffer(data=[0 0 0 0], stride=4):dxbinding(0),glbinding(0),out

RWStructuredBuffer<int> outputBuffer;

int helper(int val, int a = 16)
{
    return val + a;
}

int test(int val)
{
    return helper(val) + helper(val, 256);
}

[numthreads(4, 1, 1)]
void computeMain(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    int inVal = (int) dispatchThreadID.x;
    int outVal = test(inVal);
    outputBuffer[dispatchThreadID.x] = outVal;
}