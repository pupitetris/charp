SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema myproject
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Table `error_log`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `error_log` ;

CREATE TABLE IF NOT EXISTS `error_log` (
  `error_log_id` INT NOT NULL,
  `timestamp` TIMESTAMP NULL,
  `error_code` ENUM('USERUNK','PROCUNK','REQUNK','REPFAIL','ASSERT','USERPARMPERM','USERPERM','MAILFAIL','DATADUP','NOTFOUND','EXIT') NULL,
  `username` VARCHAR(255) NULL,
  `ip_addr` INT(11) NULL,
  `res` VARCHAR(255) NULL,
  `msg` TEXT NULL,
  `params` TEXT NULL,
  PRIMARY KEY (`error_log_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `account`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `account` ;

CREATE TABLE IF NOT EXISTS `account` (
  `persona_id` INT NOT NULL,
  `username` VARCHAR(20) NULL,
  `passwd` VARCHAR(32) NULL,
  `status` ENUM('ACTIVE','DISABLED','DELETED') NULL,
  PRIMARY KEY (`persona_id`))
ENGINE = InnoDB;

CREATE UNIQUE INDEX `account_idx` ON `account` (`username` ASC);


-- -----------------------------------------------------
-- Table `request`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `request` ;

CREATE TABLE IF NOT EXISTS `request` (
  `request_id` INT NOT NULL,
  `persona_id` INT NOT NULL,
  `timestamp` TIMESTAMP NULL,
  `ip_addr` INT(11) NULL,
  `proname` TEXT NULL,
  `params` VARCHAR(1024) NULL,
  PRIMARY KEY (`request_id`),
  CONSTRAINT `fk_request_account`
    FOREIGN KEY (`persona_id`)
    REFERENCES `account` (`persona_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_request_account_idx` ON `request` (`persona_id` ASC);


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
