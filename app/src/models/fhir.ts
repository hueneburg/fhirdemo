import {SearchOperator} from "@/models/search-operator.ts";

export interface PatientStub {
    id: string;
    name: string[];
    birthdate?: string;
    gender?: Gender;
    iterationKey: string;
}

export interface SearchParams {
    gender: Gender | null,
    name: string | null,
    birthdateFrom: string | null,
    birthdateUntil: string | null,
    operator: SearchOperator,
    count: number,
    iterationKey: string | null,
    lastId: string | null,
}

export interface Patient {
    id?: string;
    meta?: Meta;
    implicit_rules: string[];
    language?: string;
    text?: Narrative;
    contained: Resource[];
    extension: Extension[];
    modifier_extension: Extension[];
    identifier: Identifier[];
    active?: boolean;
    name: HumanName[];
    telecom: ContactPoint[];
    gender?: Gender;
    birth_date?: string;
    deceased?: Deceased;
    address?: Address;
    marital_status?: CodeableConcept;
    multiple_birth?: MultipleBirth;
    photo: Attachment[];
    contact: Contact[];
    communication: Communication[];
    general_practitioner: Reference[];
    managing_organization?: Reference;
    link: Link[];
}

export interface Meta {
    id?: string;
    extension: Extension[];
    source?: string;
    profile: string[];
    security: Coding[];
    tag: Coding[];
}

export interface Narrative {
    id?: string;
    extension: Extension[];
    status: NarrativeStatus;
    div: string;
}

export interface Resource {
    id?: string;
    meta?: Meta;
    implicit_rules: string[];
    language?: string;
}

export interface HumanName {
    id?: string;
    extension: Extension[];
    human_name_use?: HumanNameUse;
    text?: string;
    family?: string;
    given: string[];
    prefix: string[];
    suffix: string[];
    period?: Period;
}

export interface ContactPoint {
    id?: string;
    extension: Extension[];
    system?: ContactPointSystem;
    value?: string;
    contact_point_use?: ContactPointUse;
    rank?: number;
    period?: Period;
}

export interface Deceased {
    deceased?: boolean;
    date_time?: string;
}

export interface Address {
    id?: string;
    extension: Extension[];
    address_use?: AddressUse;
    address_type?: AddressType;
    text?: string;
    line: string[];
    city?: string;
    district?: string;
    state?: string;
    postal_code?: string;
    country?: string;
    period?: Period;
}

export interface MultipleBirth {
    multiple_birth?: boolean;
    count?: number;
}

export interface Attachment {
    id?: string;
    extension: Extension[];
    content_type?: string;
    language?: string;
    data?: string;
    url?: string;
    size?: number;
    hash?: string;
    title?: string;
    creation?: string; // DateTime<FixedOffset> → ISO string
}

export interface Contact {
    id?: string;
    extension: Extension[];
    modifier_extension: Extension[];
    relationship: CodeableConcept[];
    name: HumanName[];
    telecom: ContactPoint[];
    address?: Address;
    gender?: Gender;
    organization?: Reference;
    period?: Period;
}

export interface Communication {
    id?: string;
    extension: Extension[];
    modifier_extension: Extension[];
    language: string;
    preferred?: boolean;
}

export interface Extension {
    id?: string;
    extension: Extension[];
    url: string;
    value_base_64_binary?: string;
    value_boolean?: boolean;
    value_string?: string;
    value_integer?: number;
}

export interface Coding {
    id?: string;
    extension: Extension[];
    system?: string;
    version?: string;
    code?: string;
    display?: string;
    user_selected?: boolean;
}

export interface CodeableConcept {
    id?: string;
    extension: Extension[];
    coding: Coding[];
    text?: string;
}

export interface Identifier {
    id?: string;
    extension: Extension[];
    identifier_use?: IdentifierUse;
    identifier_type?: CodeableConcept;
    system?: string;
    value?: string;
    period?: Period;
    assigner?: Reference;
}

export interface Period {
    start?: string;
    end?: string;
}

export interface Reference {
    id?: string;
    extension: Extension[];
    reference?: string;
    ref_type?: string;
    identifier?: Identifier;
    display?: string;
}

export interface Link {
    other: Reference;
    link_type: LinkType;
}

export enum IdentifierUse {
    usual = "USUAL",
    official = "OFFICIAL",
    temp = "TEMP",
    secondary = "SECONDARY",
    old = "OLD",
}

export enum LinkType {
    replacedBy = "REPLACED-BY",
    replaces = "REPLACES",
    refer = "REFER",
    seealso = "SEEALSO",
}

export enum NarrativeStatus {
    generated = "GENERATED",
    extensions = "EXTENSIONS",
    additional = "ADDITIONAL",
    empty = "EMPTY",
}

export enum HumanNameUse {
    usual = "USUAL",
    official = "OFFICIAL",
    temp = "TEMP",
    nickname = "NICKCNAME",
    anonymous = "ANONYMOUS",
    old = "OLD",
    maiden = "MAIDEN",
}

export enum ContactPointUse {
    home = "HOME",
    work = "WORK",
    temp = "TEMP",
    old = "OLD",
    mobile = "MOBILE",
}

export enum ContactPointSystem {
    phone = "PHONE",
    fax = "FAX",
    email = "EMAIL",
    pager = "PAGER",
    url = "URL",
    sms = "SMS",
    other = "OTHER",
}

export enum Gender {
    male = "MALE",
    female = "FEMALE",
    other = "OTHER",
    unknown = "UNKNOWN",
}

export enum AddressUse {
    home = "HOME",
    work = "WORK",
    temp = "TEMP",
    old = "OLD",
    billing = "BILLING",
}

export enum AddressType {
    postal = "POSTAL",
    physical = "PHYSICAL",
    both = "BOTH",
}
