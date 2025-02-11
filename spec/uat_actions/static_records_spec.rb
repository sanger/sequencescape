# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UatActions::StaticRecords, type: :module do
  describe '.collection_site' do
    it 'returns the correct collection site' do
      expect(described_class.collection_site).to eq('Sanger')
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  describe '.supplier' do
    it 'creates or finds the supplier' do
      supplier = described_class.supplier
      expect(supplier).to be_a(Supplier)
      expect(supplier.name).to eq('UAT Supplier')
    end
  end

  describe '.tube_purpose' do
    it 'creates or finds the tube purpose' do
      tube_purpose = described_class.tube_purpose
      expect(tube_purpose).to be_a(Purpose)
      expect(tube_purpose.name).to eq('LCA Blood Vac')
    end
  end

  describe '.study' do
    it 'creates or finds the study' do
      study = described_class.study
      expect(study).to be_a(Study)
      expect(study.name).to eq('UAT Study')
    end
  end

  describe '.study_type' do
    it 'creates or finds the study type' do
      study_type = described_class.study_type
      expect(study_type).to be_a(StudyType)
      expect(study_type.name).to eq('UAT')
    end
  end

  describe '.data_release_study_type' do
    it 'creates or finds the data release study type' do
      data_release_study_type = described_class.data_release_study_type
      expect(data_release_study_type).to be_a(DataReleaseStudyType)
      expect(data_release_study_type.name).to eq('UAT')
    end
  end

  describe '.project' do
    it 'creates or finds the project' do
      project = described_class.project
      expect(project).to be_a(Project)
      expect(project.name).to eq('UAT Project')
    end
  end

  describe '.budget_division' do
    it 'creates or finds the budget division' do
      budget_division = described_class.budget_division
      expect(budget_division).to be_a(BudgetDivision)
      expect(budget_division.name).to eq('UAT TESTING')
    end
  end

  describe '.program' do
    it 'creates or finds the program' do
      program = described_class.program
      expect(program).to be_a(Program)
      expect(program.name).to eq('UAT')
    end
  end

  describe '.user' do
    it 'creates or finds the user' do
      user = described_class.user
      expect(user).to be_a(User)
      expect(user.login).to eq('__uat_test__')
    end
  end

  describe '.faculty_sponsor' do
    it 'creates or finds the faculty sponsor' do
      faculty_sponsor = described_class.faculty_sponsor
      expect(faculty_sponsor).to be_a(FacultySponsor)
      expect(faculty_sponsor.name).to eq('UAT Faculty Sponsor')
    end
  end

  describe '.order_role' do
    it 'creates or finds the order role' do
      order_role = described_class.order_role
      expect(order_role).to be_a(OrderRole)
      expect(order_role.role).to eq('UAT Order Role')
    end
  end

  # rubocop:enable RSpec/MultipleExpectations
end
