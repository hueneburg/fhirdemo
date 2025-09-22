use crate::db::db::Db;
use crate::model::model::{Address, Attachment, CodeableConcept, Coding, Communication, Contact, ContactPoint, Extension, HumanName, Identifier, Meta, Narrative, Patient, Reference, Resource};
use futures::future::BoxFuture;
use futures::FutureExt;

pub trait SetId {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>>;
}

impl SetId for Patient {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            if let Some(meta) = &mut self.meta {
                meta.set_id(db).await?;
            }
            if let Some(text) = &mut self.text {
                text.set_id(db).await?;
            }
            for e in &mut self.contained {
                e.set_id(db).await?;
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            for e in &mut self.modifier_extension {
                e.set_id(db).await?;
            }
            for e in &mut self.identifier {
                e.set_id(db).await?;
            }
            for e in &mut self.name {
                e.set_id(db).await?;
            }
            for e in &mut self.telecom {
                e.set_id(db).await?;
            }
            if let Some(address) = &mut self.address {
                address.set_id(db).await?;
            }
            if let Some(marital_status) = &mut self.marital_status {
                marital_status.set_id(db).await?;
            }
            for e in &mut self.photo {
                e.set_id(db).await?;
            }
            for e in &mut self.contact {
                e.set_id(db).await?;
            }
            for e in &mut self.communication {
                e.set_id(db).await?;
            }
            for e in &mut self.general_practitioner {
                e.set_id(db).await?;
            }
            if let Some(managing_organization) = &mut self.managing_organization {
                managing_organization.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Meta {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            for e in &mut self.security {
                e.set_id(db).await?;
            }
            for e in &mut self.tag {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Narrative {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Resource {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            if let Some(meta) = &mut self.meta {
                meta.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for HumanName {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for ContactPoint {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Address {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Attachment {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Contact {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            for e in &mut self.modifier_extension {
                e.set_id(db).await?;
            }
            for e in &mut self.relationship {
                e.set_id(db).await?;
            }
            for e in &mut self.name {
                e.set_id(db).await?;
            }
            for e in &mut self.telecom {
                e.set_id(db).await?;
            }
            if let Some(address) = &mut self.address {
                address.set_id(db).await?;
            }
            if let Some(organization) = &mut self.organization {
                organization.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Communication {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            for e in &mut self.modifier_extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Extension {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                Box::pin(e.set_id(db)).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Coding {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for CodeableConcept {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            for e in &mut self.coding {
                e.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Identifier {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            if let Some(identifier_type) = &mut self.identifier_type {
                identifier_type.set_id(db).await?;
            }
            if let Some(assigner) = &mut self.assigner {
                assigner.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}

impl SetId for Reference {
    fn set_id<'a>(&'a mut self,
                        db: &'a Db,
    ) -> BoxFuture<'a, Result<(), Box<dyn std::error::Error>>> {
        return async move {
            if self.id == None {
                self.id = Some(db.get_id().await?)
            }
            for e in &mut self.extension {
                e.set_id(db).await?;
            }
            if let Some(identifier) = &mut self.identifier {
                identifier.set_id(db).await?;
            }
            return Ok(());
        }.boxed();
    }
}
