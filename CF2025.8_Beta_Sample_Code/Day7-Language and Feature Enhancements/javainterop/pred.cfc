//pred.cfc
component implements = "java:java.util.function.Predicate"
{
    public boolean function test(any input)
    {
        return len(input) == 6
    }
}

