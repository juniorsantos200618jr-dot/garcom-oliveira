# Garçom Fácil — MVP Android

Primeira versão funcional do app de garçom solicitado.

## O que já está feito

- Login simples de garçom.
- 20 mesas.
- Cardápio por setor: churrasqueira, cozinha e bar.
- Carrinho com quantidade e observação do item.
- Envio do pedido.
- Separação automática dos itens por setor.
- Fila de produção com status Pendente / Preparando / Pronto.
- Persistência local dos pedidos no celular com `shared_preferences`.
- Impressão ESC/POS por IP/TCP, porta 9100.
- Configuração separada de impressora para churrasqueira, cozinha e bar.
- Se não houver impressora configurada, o app entra em modo de impressão simulada.

## Importante sobre os dados

A versão atual salva no próprio aparelho para o MVP. Para não depender de um único celular e ter backup real, a próxima etapa é ligar o app a um banco online (recomendado: Supabase ou Firebase). Assim vários garçons podem usar celulares diferentes e todos enxergam os mesmos pedidos.

## Como gerar o projeto Android

1. Instale o Flutter SDK e o Android Studio no computador.
2. Crie a estrutura Android na pasta do projeto:

```bash
flutter create . --platforms android --org com.garcomfacil
```

3. Baixe as dependências:

```bash
flutter pub get
```

4. Com o celular Android conectado e Depuração USB ativada:

```bash
flutter run
```

5. Para gerar um APK:

```bash
flutter build apk --release
```

O APK ficará normalmente em:
`build/app/outputs/flutter-apk/app-release.apk`

## Login de teste

- Usuário: `garcom`
- Senha: `1234`

Neste MVP qualquer usuário/senha não vazios entra; a autenticação real será ligada ao banco online depois.

## Configurar impressora térmica

No app, abra **Configurações** e informe o IP de cada impressora. Exemplo:

- Churrasqueira: `192.168.1.50`
- Cozinha: `192.168.1.51`
- Bar: `192.168.1.52`

A porta utilizada é `9100`, comum em impressoras ESC/POS com rede Ethernet/Wi-Fi. A impressora e o celular precisam estar na mesma rede local.

## Próximas etapas recomendadas

1. Banco online e backup.
2. Login real por funcionário.
3. Cadastro de produtos/categorias/preços pelo painel administrativo.
4. Cadastro de mesas e comandas.
5. Fechamento de conta e formas de pagamento.
6. Histórico e relatórios.
7. Reimpressão de pedido.
8. Controle de permissões (garçom, caixa, gerente).
9. Nome/logo do cliente.
10. Teste com o modelo exato da impressora térmica.
