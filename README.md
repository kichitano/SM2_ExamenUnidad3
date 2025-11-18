# EXAMEN 3RA UNIDAD


**CURSO**: SOLUCIONES MOVILES II
**NOMBRES**: Christian Alexander Cespedes Medina
**URL REPOSITORIO**: https://github.com/kichitano/SM2_ExamenUnidad3

*Estructura de Carpertas*
Carpetas WorkFlow y Tests

<img width="413" height="189" alt="image" src="https://github.com/user-attachments/assets/f140c5e9-fb42-4a99-9a74-122bc738c2a2" />

Aqui encontramos la estructura original del repo.



<img width="531" height="98" alt="image" src="https://github.com/user-attachments/assets/cabd77e2-3697-48a8-80e2-c111b0ec3aa6" />

Ubicacion del fichero quality-check.yml



<img width="873" height="445" alt="image" src="https://github.com/user-attachments/assets/27156fb4-b37d-4a8e-9c0d-c9cc0a7f1e52" />

Ubicacion de la carpeta test del proyecto de backend



<img width="886" height="581" alt="image" src="https://github.com/user-attachments/assets/6c7b8e1c-f450-40da-8ab8-a5c0076b2e39" />

Ubicacion de la carpeta test del proyecto de frontend



*Contenido Original del fichero quality-check.yml*


<img width="479" height="529" alt="image" src="https://github.com/user-attachments/assets/8856652f-9d26-451a-9335-b31c1812dfcf" />

Al subir el archivo se ejecutara y evaluara segun lo especificado en el contenido



<img width="1291" height="238" alt="image" src="https://github.com/user-attachments/assets/1e6322cb-caa5-49e7-9616-fcfd1a8277a9" />

Como las carpetas de los tests se encuentran en distintos lugares y ademas son 2 proyectos procedemos a configurar el archivo quality-check.yml



<img width="886" height="1140" alt="image" src="https://github.com/user-attachments/assets/5a91da5d-6039-495c-a323-89c083c75671" />

Una vez configurados los parametros correctos procedemos a actualizar nuestro archivo en el repositorio y esperamos la ejecucion automatica del workflow.



<img width="886" height="618" alt="image" src="https://github.com/user-attachments/assets/d0e9fe81-9630-4230-b0e5-a1e4be57a4e5" />

Vemos que el workflow ya funciona aunque nos genero error.



<img width="886" height="251" alt="image" src="https://github.com/user-attachments/assets/e5c17478-0a18-4e98-b225-eab0242661d0" />

Actualmente tenemos 2 registros debido al primer workflow y a su modificacion para la lectura de las carpetas, procedemos a corregir el codigo y esperamos su ejecution.



<img width="886" height="630" alt="image" src="https://github.com/user-attachments/assets/61e4ff92-8fb2-49c8-8387-bf575c124a46" />

En esta actualización se elimino codigo no utilizado, se cambio el metodo print a debugPrint (en todos los archivos) y tambien se actualizo el metodo .withOpacity() por estar ya deprecado



<img width="886" height="355" alt="image" src="https://github.com/user-attachments/assets/d447651f-07a8-45f3-92ef-422951c8a65a" />

Esperamos para visualizar el resultado de la ejecucion



<img width="886" height="752" alt="image" src="https://github.com/user-attachments/assets/8a42689b-7511-46fd-ba0d-b6f33d567b85" />

Como vemos el resultado del quality-check.yml es positivo para el frontend, ahora se corregira el frontend para que pueda reevaluar el repositorio.



<img width="688" height="1014" alt="image" src="https://github.com/user-attachments/assets/a8e67a57-9e59-4cd2-86d2-8229d793b84e" />

Procedemos a subir los cambios realizados los cuales involucran archivos no existentes y variables tipo any.



<img width="852" height="286" alt="image" src="https://github.com/user-attachments/assets/10df2ce7-18fe-4996-9b1c-7563ff649847" />


<img width="507" height="515" alt="image" src="https://github.com/user-attachments/assets/63990ffe-d734-4876-9f30-0e31aef07436" />

Ya que tenemos un problema al subir los ficheros por github desktop, procederemos a subirlos manualmente por la web



<img width="1260" height="751" alt="image" src="https://github.com/user-attachments/assets/f97a636e-9478-424c-af2f-98c7e513e2ab" />

Subiendo los archivos manualmente para proceder a ejecutar el workflow



<img width="1576" height="933" alt="image" src="https://github.com/user-attachments/assets/1263d6ef-1a89-4116-ac19-26b6821a4834" />

Podemos observar que tenemos muchos workflows ejecutandose, y eso se debe a que cada subida de archivos (permite solo 100 en la web) va ejecutando el workflow y como nuestro backend tiene mas de 100 se ejecuta por cada commit realizado. Esperamos a finalizar su ejecucion y para corroborar al final realizaremos un re-run.













