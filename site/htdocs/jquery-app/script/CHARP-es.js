// This file is part of the CHARP project.
//
// Copyright © 2011 - 2014
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

CHARP.ERRORS['HTTP:CONNECT'].desc	=  'No fue posible contactar al servicio web.';
CHARP.ERRORS['HTTP:CONNECT'].msg	=  'Verifique que su conexión a internet funcione y vuelva a intentar.';
CHARP.ERRORS['HTTP:SRVERR'].desc	=  'El servidor web respondió con un error.';
CHARP.ERRORS['AJAX:JSON'].desc		=  'Los datos obtenidos del servidor están mal formados.';
CHARP.ERRORS['AJAX:UNK'].desc		=  'Un tipo de error no reconocido ha ocurrido.';

CHARP.ERROR_SEV_MSG = [
    undefined,
    /* INTERNAL */ 'Este es un error interno en el sistema. Por favor anote la información proporcionada en este mensaje y llame a soporte para que se trabaje en una solución.',
    /* PERM */     'Está tratando de acceder a datos a los que no tiene autorización. Si requiere mayor acceso, llame a soporte.',
    /* RETRY */    'Este es un error temporal, por favor vuelva a intentar inmediatamente o en unos minutos. Si el error persiste, llame a soporte.',
    /* USER */     'La información que proporcionó es errónea, por favor corrija sus datos y vuelva a intentar.',
    /* EXIT */     'Este es un mensaje enviado para proceso por parte de la aplicación y no debe ser visible al usuario.'
];
