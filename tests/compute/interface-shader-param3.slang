// interface-shader-param3.slang

// This test builds on `interface-shader-param2.slang` by putting
// interface types at more complicated places in the overall layout.
//

//TEST(compute):COMPARE_COMPUTE_EX:-slang -compute
//TEST(compute):COMPARE_COMPUTE_EX:-slang -compute -dx12
//TEST(compute, vulkan):COMPARE_COMPUTE_EX:-vk -compute

// A lot of the setup is the same as for `interface-shader-param`,
// so look there if you want the comments.

interface IRandomNumberGenerator
{
    [mutating]
    int randomInt();
}

interface IRandomNumberGenerationStrategy
{
    associatedtype Generator : IRandomNumberGenerator;
    Generator makeGenerator(int seed);
}

interface IModifier
{
    int modify(int val);
}

int test(
    int                             seed,
    IRandomNumberGenerationStrategy inStrategy,
    IModifier                       modifier)
{
    let strategy = inStrategy;
    var generator = strategy.makeGenerator(seed);
    let unused = generator.randomInt();
    let val = generator.randomInt();
    let modifiedVal = modifier.modify(val);
    return modifiedVal;
}


//TEST_INPUT:ubuffer(data=[0 0 0 0], stride=4):dxbinding(0),glbinding(0),out
RWStructuredBuffer<int> gOutputBuffer;

// Note: while we declare `gStrategy` here, there is no matching
// line providing input data at this point. That is partly to
// work around an apparent bug in the test runner, but it is also
// to reflect the fact that this declaration does not cause a
// constant buffer binding to be allocated, because just from
// the declaration of `gStrategy` we cannot tell whether a
// constant buffer binding is even needed (there might be no
// uniform/ordinary data).
//
ConstantBuffer<IRandomNumberGenerationStrategy> gStrategy;

[numthreads(4, 1, 1)]
void computeMain(

// We will be declaring two different `uniform` parameters in the
// entry-point parameter list, which will both get allocated to
// the same constant buffer.
//
// The first parameter will use an interface type, while the second
// will be plain-old-data.
//
    uniform IModifier   modifier,
    uniform int         extra,
//
// The computed layout for the entry-point constant buffer will
// always place the non-interface-type data first, so the first
// four bytes of our buffer represent the `extra` field.
//
// After all the non-interface-type data is laid out, we lay out
// the contents of extistential value slots in order, using the
// ordinary constant buffer packing rules. Because the concrete
// type we'll be plugging in for `modifier` is a `struct` type,
// it will need to start on a 16-byte-aligned boundary.
//
// Here's the incantation to make the test runner fill in the constant buffer:
//
//TEST_INPUT:cbuffer(data=[256 0 0 0 16 0 0 0], stride=4):dxbinding(0),glbinding(1)
//
// So, the value `256` will be used for `extra` and the value `16`
// will be written to the first four bytes of the concrete value
// being used for `modifier`.

            uint3       dispatchThreadID : SV_DispatchThreadID)
{
    let tid = dispatchThreadID.x;

    let inputVal : int = tid;
    let outputVal = test(inputVal, gStrategy, modifier)
    	+ extra*extra;

    gOutputBuffer[tid] = outputVal;
}

// Okay, now we get to the part that is unique starting
// in this test: we add data to the concrete types
// that we will use as parameters.

struct MyStrategy : IRandomNumberGenerationStrategy
{
    int globalSeed;

    struct Generator : IRandomNumberGenerator
    {
        int state;

        [mutating]
        int randomInt()
        {
            return state++;
        }
    }

    Generator makeGenerator(int seed)
    {
        Generator generator = { seed ^ globalSeed };
        return generator;
    }
}

struct MyModifier : IModifier
{
    int localModifier;

    int modify(int val)
    {
        return val * localModifier;
    }
}

//TEST_INPUT: globalExistentialType MyStrategy
//TEST_INPUT: entryPointExistentialType MyModifier

// Once the concrete types are plugged in, the compiler can
// see that `gStrategy` needs a constant buffer register/binding.
// It will alocate the location for `gStrategy` after all other
// shader parameters, to ensure that different specializations
// of the same shader will agree on the locations for all the
// non-interface-type parameters.
//
//TEST_INPUT:cbuffer(data=[1 0 0 0], stride=4):dxbinding(1),glbinding(2)


