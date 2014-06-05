BEGIN TRANSACTION;
      SET CONSTRAINTS ALL DEFERRED;

      -- password is ``blah''
      INSERT INTO account(persona_id, username, passwd, status)
      	     VALUES (DEFAULT, 'testuser', '6f1ed002ab5595859014ebf0951522d9', 'ACTIVE');

CREATE OR REPLACE FUNCTION rp_anon_get_random_bytes(_start character varying, _end character varying)
  RETURNS TABLE(random text) AS
$BODY$
BEGIN
	random := _start || encode(gen_random_bytes(32), 'hex') || _end;
	RETURN NEXT;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION rp_file_image_test(_filename varchar)
  RETURNS TABLE(mimetype text, filename text) AS
$BODY$
BEGIN
	mimetype := 'image/png';
	filename := _filename;
	RETURN NEXT;
END
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


COMMIT TRANSACTION;
