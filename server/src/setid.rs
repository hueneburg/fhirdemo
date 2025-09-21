use crate::db::db::Db;
use crate::model::model::{Address, Attachment, CodeableConcept, Coding, Communication, Contact, ContactPoint, Extension, HumanName, Identifier, Meta, Narrative, Patient, Reference, Resource};

pub trait SetId {
    async fn set_id(&mut self, db: &Db);
}

impl SetId for Patient {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        if self.meta != None {
            self.meta.as_mut().unwrap().set_id(db).await;
        }
        if self.text != None {
            self.text.as_mut().unwrap().set_id(db).await;
        }
        for e in &mut self.contained {
            e.set_id(db).await;
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        for e in &mut self.modifier_extension {
            e.set_id(db).await;
        }
        for e in &mut self.identifier {
            e.set_id(db).await;
        }
        for e in &mut self.name {
            e.set_id(db).await;
        }
        for e in &mut self.telecom {
            e.set_id(db).await;
        }
        if self.address != None {
            self.address.as_mut().unwrap().set_id(db).await;
        }
        if self.marital_status != None {
            self.marital_status.as_mut().unwrap().set_id(db).await;
        }
        for e in &mut self.photo {
            e.set_id(db).await;
        }
        for e in &mut self.contact {
            e.set_id(db).await;
        }
        for e in &mut self.communication {
            e.set_id(db).await;
        }
        for e in &mut self.general_practitioner {
            e.set_id(db).await;
        }
        if self.managing_organization != None {
            self.managing_organization.as_mut().unwrap().set_id(db).await;
        }
    }
}

impl SetId for Meta {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        for e in &mut self.security {
            e.set_id(db).await;
        }
        for e in &mut self.tag {
            e.set_id(db).await;
        }
    }
}

impl SetId for Narrative {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for Resource {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        if self.meta != None {
            self.meta.as_mut().unwrap().set_id(db).await;
        }
    }
}

impl SetId for HumanName {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for ContactPoint {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for Address {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for Attachment {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for Contact {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        for e in &mut self.modifier_extension {
            e.set_id(db).await;
        }
        for e in &mut self.relationship {
            e.set_id(db).await;
        }
        for e in &mut self.name {
            e.set_id(db).await;
        }
        for e in &mut self.telecom {
            e.set_id(db).await;
        }
        if self.address != None {
            self.address.as_mut().unwrap().set_id(db).await;
        }
        if self.organization != None {
            self.organization.as_mut().unwrap().set_id(db).await;
        }
    }
}

impl SetId for Communication {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        for e in &mut self.modifier_extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for Extension {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            Box::pin(e.set_id(db)).await;
        }
    }
}

impl SetId for Coding {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
    }
}

impl SetId for CodeableConcept {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        for e in &mut self.coding {
            e.set_id(db).await;
        }
    }
}

impl SetId for Identifier {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        if self.identifier_type != None {
            self.identifier_type.as_mut().unwrap().set_id(db).await;
        }
        if self.assigner != None {
            Box::pin(self.assigner.as_mut().unwrap().set_id(db)).await;
        }
    }
}

impl SetId for Reference {
    async fn set_id(&mut self, db: &Db) {
        if self.id == None {
            self.id = Some(db.get_id().await.to_string())
        }
        for e in &mut self.extension {
            e.set_id(db).await;
        }
        if self.identifier != None {
            self.identifier.as_mut().unwrap().set_id(db).await;
        }
    }
}
