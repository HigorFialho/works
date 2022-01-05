CREATE TABLE #TempColaborador
(
	[cd_usuario_sistema] [char] (6),
	[nom_usuario_sistema] [varchar] (50)
)
INSERT INTO #TempColaborador ([cd_usuario_sistema], [nom_usuario_sistema])
    (
	SELECT u.[cd_usuario_sistema], u.[nom_usuario_sistema] FROM [Corp].[dbo].[vco_usuario_sistema] u
	)

declare @DataInicio smalldatetime = '2020-01-01 00:00:01'
declare @DataFim smalldatetime = getdate()

SELECT
	 a.[id_solicitacao]
	,a.[cd_empresa]
	,[Chave] = cast(a.[cd_empresa] as varchar) + cast(a.[id_solicitacao] as varchar)
	,[Solicitante] = (SELECT [nom_usuario_sistema] FROM #TempColaborador WHERE [cd_usuario_sistema] = a.[cd_solicitante]) --a.[cd_solicitante]
	,[dt_solicitacao] = cast(a.[dt_solicitacao] as smalldatetime)
	,a.[cd_tipo_solicitacao]
	,a.[cd_agencia]
	,[Comprador] = b.[nome_comprador] --a.[cd_comprador]
	,b.[cd_tipo_seg_comprador]
	,[Aprovador] = (SELECT [nom_usuario_sistema] FROM #TempColaborador WHERE [cd_usuario_sistema] = a.[cd_aprovador]) --a.[cd_aprovador]
	,[Reprovador] = (SELECT [nom_usuario_sistema] FROM #TempColaborador WHERE [cd_usuario_sistema] = a.[cd_reprovador]) --a.[cd_reprovador]
	,[dt_aprovacao_reprovacao] = cast(a.[dt_aprovacao_reprovacao] as smalldatetime)
	,[Ano] = year(a.[dt_aprovacao_reprovacao])
	,[Mes] = month(a.[dt_aprovacao_reprovacao])
	,a.[txt_observacao_reprovacao]
	,a.[idc_despachante_parcelado]
	,a.[idc_cheque_vencido]
	,a.[idc_vlr_cartao_acima_perm]
	,a.[idc_anexo]
	,[tempo_solucao] = cast(datediff(ss,a.[dt_solicitacao],a.[dt_aprovacao_reprovacao]) as float)/(86400)
	,[status_solicitacao] = case 
								when a.[cd_aprovador] is null and a.[cd_reprovador] is null then 'Aguardando'
								when a.[cd_aprovador] is not null and a.[cd_reprovador] is null then 'Aprovada'
								when a.[cd_aprovador] is null and a.[cd_reprovador] is not null then 'Reprovada'
								when a.[cd_aprovador] is not null and a.[cd_reprovador] is not null then 'Aprovada/Reprovada'
								else null
							end
	,h.[cd_regional]
	,[Tipo Regional] = case
							when h.[cd_regional] = 'ATA '	then '1'
							when h.[cd_regional] = 'ASL '	then '1'
							when h.[cd_regional] = 'LEI '	then '1'
							when h.[cd_regional] = 'RVV '	then '-1'
							when h.[cd_regional] = 'SPA '	then '1'
							when h.[cd_regional] = 'CDS '	then '1'
							when h.[cd_regional] = 'GRJ '	then '1'
							when h.[cd_regional] = 'CDN '	then '1'
							when h.[cd_regional] = 'HTZ '	then '1'
							when h.[cd_regional] = 'CAV '	then '1'
							when h.[cd_regional] = 'SUL '	then '0'
							when h.[cd_regional] = 'NOR '	then '0'
							when h.[cd_regional] = 'GSP '	then '0'
							when h.[cd_regional] = 'SAO '	then '0'
							when h.[cd_regional] = 'RIO '	then '0'
							when h.[cd_regional] = 'NDE '	then '0'
							when h.[cd_regional] = 'CEN '	then '0'
							when h.[cd_regional] = 'SPI '	then '0'
							when h.[cd_regional] = 'COE '	then '0'
							when h.[cd_regional] = 'NDL '	then '0'
							when h.[cd_regional] = 'SSE '	then '0'
							else '-1'
						end
FROM [SKT].[dbo].[fvs_parcela_solicita_negoc] a
		left join [SKT].[dbo].[vsn_comprador] b
			on a.[cd_comprador] = b.[cod_comprador]
		left join (
					SELECT 
						 T2.[cd_agencia]
						,ISNULL(T4.cd_regional, -1) AS cd_regional
					FROM Corp.dbo.vco_agencia T2
					LEFT JOIN (
								SELECT cr.cd_filial, Max(cr.cd_seq_regional) AS cd_seq_regional
								FROM Corp.dbo.vco_composicao_regional cr
								GROUP BY cr.cd_filial
								) T3
						ON T3.cd_filial = T2.cd_filial
					LEFT JOIN Corp.dbo.vco_regional T4
						ON T4.cd_seq_regional = T3.cd_seq_regional
					) h
			on a.[cd_agencia] = h.[cd_agencia]
	where a.[dt_aprovacao_reprovacao] between @DataInicio and @DataFim

DROP TABLE #TempColaborador