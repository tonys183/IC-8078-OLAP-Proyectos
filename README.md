# IC-8078 — Almacenes de Datos y Procesamiento OLAP

Proyectos del curso Almacenes de Datos y Procesamiento OLAP (IC-8078), centrados en una solución de inteligencia de negocios para una librería. Los tres trabajos abarcan el diseño del almacén de datos, su alimentación mediante procesos ETL y la construcción de un cubo con visualizaciones para apoyar la toma de decisiones.

## Proyecto I (Diseño del almacén de datos)

El proyecto consistía en diseñar un almacén de datos a partir de las necesidades de análisis de un negocio. En este caso, se tomó como base una librería que comercializa libros, suministros y servicios, con el propósito de organizar la información de sus operaciones para consultar ventas y estudiar el comportamiento del negocio desde distintas perspectivas.

Para resolverlo, se definió una base de datos transaccional en SQL Server con clientes, artículos, pedidos y sus detalles, además de información propia de los libros, como autores, editoriales y géneros. A partir de esa estructura se planteó el modelo multidimensional, identificando dimensiones, jerarquías y medidas que permitieran transformar los registros operativos en información útil para el análisis.

## Proyecto II (Procesos ETL y cargas incrementales)

El proyecto consistía en alimentar el almacén de datos diseñado en el primer trabajo mediante un proceso de extracción, transformación y carga (ETL). La propuesta debía trasladar los datos del sistema transaccional hacia el modelo analítico e incorporar nuevos registros mediante cargas incrementales, evitando repetir la carga completa en cada ejecución.

La solución utiliza SQL Server Integration Services (SSIS) con paquetes desarrollados en Visual Studio. Se configuró Change Data Capture (CDC) en la base de datos de origen y se crearon tablas intermedias de staging para recibir los registros. El flujo se dividió en una etapa de extracción hacia staging y otra de transformación y carga hacia las dimensiones y la tabla de hechos, que reúne cantidades, montos, costos y ganancias para el análisis de las ventas.

## Proyecto III (Cubo OLAP y dashboards)

El proyecto consistía en utilizar el almacén de datos de los trabajos anteriores para construir un cubo multidimensional y presentar indicadores del negocio mediante dashboards. El objetivo era facilitar la exploración de los resultados de la librería y responder preguntas de análisis mediante distintas dimensiones y niveles de detalle.

Para resolverlo, se desarrolló un proyecto de SQL Server Analysis Services (SSAS) con un cubo y dimensiones de clientes, artículos y tiempo. El repositorio incluye un dashboard de Power BI y un archivo de Excel para la consulta y visualización de los datos, completando el recorrido desde los registros transaccionales hasta la presentación de información para la toma de decisiones.
