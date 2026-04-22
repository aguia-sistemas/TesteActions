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
    public void BomDia_ComNome_RetornaSaudacao()
    {
        var teste = new Teste();
        Assert.Equal("Bom dia, Leandro!", teste.BomDia("Leandro"));
    }
}
