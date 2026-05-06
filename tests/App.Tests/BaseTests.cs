namespace App.Tests;

public class BaseTests
{
    [Fact]
    public void Teste_valor()
    {
        var teste = new Teste();
        Assert.Equal("valor, Teste!", teste.Valor("Teste"));
    }
    
    [Fact]
    public void Teste_valor2()
    {
        var teste = new Teste();
        Assert.Equal("valor2, Teste!", teste.Valor2("Teste"));
    }
    
    [Fact]
    public void Teste_valor3()
    {
        var teste = new Teste();
        Assert.Equal("valor3, Teste!", teste.Valor3("Teste"));
    }
    
    [Fact]
    public void Teste_valor4()
    {
        var teste = new Teste();
        Assert.Equal("valor4, Teste!", teste.Valor4("Teste"));
    }
    
    [Fact]
    public void Teste_valor5()
    {
        var teste = new Teste();
        Assert.Equal("valor5, Teste!", teste.Valor5("Teste"));
    }
    
    [Fact]
    public void Teste_valor6()
    {
        var teste = new Teste();
        Assert.Equal("valor6, Teste!", teste.Valor6("Teste"));
    }
}
