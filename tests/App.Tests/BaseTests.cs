namespace App.Tests;

public class BaseTests
{
    [Fact]
    public void Teste_valor()
    {
        var teste = new Teste();
        Assert.Equal("valor, Teste!", teste.Valor("Teste"));
    }
}
