# Extract Dominant Color

Package Flutter para extrair a cor dominante de imagens.

## Como funciona

O package utiliza algoritmos de quantização de cores para identificar a cor mais dominante em uma imagem. O processo inclui:

1. **Redimensionamento**: A imagem é redimensionada para 112x112 pixels para otimizar performance
2. **Quantização**: Utiliza o algoritmo Celebi para agrupar cores similares
3. **Análise**: Identifica a cor mais frequente na imagem
4. **Retorno**: Retorna a cor dominante como um objeto `Color`

## API

### `fromImage(ImageProvider provider)`

Extrai a cor dominante de uma imagem.

**Parâmetros:**
- `provider`: ImageProvider (NetworkImage, AssetImage, etc.)

**Retorna:**
- `Future<Color?>`: Cor dominante ou null se não conseguir extrair
