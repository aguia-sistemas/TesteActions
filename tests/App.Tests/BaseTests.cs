namespace App.Tests;

public class BaseTests
{
    [Fact]
    public void Teste_valor()
    {
        var teste = new Teste();
        Assert.Equal("valor, Teste", teste.Valor("Teste"));
    }
    
    [Fact]
    public void Teste_valor2()
    {
        var teste = new Teste();
        Assert.Equal("valor2, Teste!", teste.Valor2("Teste"));
    }
}
